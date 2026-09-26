"""Migración ÚNICA: Firestore → base de datos de usuarios del backend.

Antes la app guardaba perfil y progreso en Firestore:
    /usuarios/{uid}                       nombre, grado, personaje, email, edad, genero, fecha_registro
    /usuarios/{uid}/progreso/{docId}      grado, materia, actividad, porcentaje, intentos, ultima_vez

Este script los copia a la base del backend (la de USERS_DATABASE_URL). Es seguro
repetirlo:
  · el perfil solo se crea si el servidor aún no tiene uno (no pisa datos más nuevos);
  · el progreso se fusiona con la regla de la app: gana el mayor avance.

Uso (ver backend/README.md, sección "Migrar datos de Firestore"):
    set GOOGLE_APPLICATION_CREDENTIALS=C:\\ruta\\fuera-del-repo\\clave.json
    set USERS_DATABASE_URL=postgresql+psycopg://...        (la BD de destino)
    python scripts/migrar_firestore.py --dry-run           (solo informa)
    python scripts/migrar_firestore.py                     (escribe)

NO guardes la clave de servicio dentro del repositorio.
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass, field
from typing import Any, Iterable, Iterator

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from pydantic import ValidationError  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402

from app.users.models import Perfil, Progreso  # noqa: E402
from app.users.schemas import PerfilIn, ProgresoItem  # noqa: E402


# ── Conversión y validación (pura: sin Firestore ni base de datos) ───────────

def _int(valor: Any, defecto: int | None = None) -> int | None:
    try:
        return int(float(valor))
    except (TypeError, ValueError):
        return defecto


def _texto(valor: Any, maximo: int) -> str | None:
    if valor is None:
        return None
    t = str(valor).strip()
    return t[:maximo] if t else None


def convertir_perfil(datos: dict) -> PerfilIn:
    """Lanza ValidationError si el perfil no sirve."""
    return PerfilIn(
        nombre=_texto(datos.get("nombre"), 60) or "Estudiante",
        grado=_int(datos.get("grado"), 1),
        personaje=_texto(datos.get("personaje"), 30) or "pollito",
        email=_texto(datos.get("email"), 254),
        edad=_int(datos.get("edad")),
        genero=_texto(datos.get("genero"), 20),
        fecha_registro=_texto(datos.get("fecha_registro"), 40),
    )


def convertir_progreso(datos: dict) -> ProgresoItem:
    """Lanza ValidationError si el registro no sirve."""
    porcentaje = float(datos.get("porcentaje", 0) or 0)
    return ProgresoItem(
        grado=_int(datos.get("grado")),
        materia=str(datos.get("materia", "")).strip().lower(),
        actividad=str(datos.get("actividad", "")).strip()[:120],
        porcentaje=max(0.0, min(100.0, porcentaje)),
        intentos=max(0, _int(datos.get("intentos"), 0) or 0),
        ultima_vez=_texto(datos.get("ultima_vez"), 40),
    )


# ── Escritura en la base del backend ─────────────────────────────────────────

@dataclass
class Resumen:
    usuarios: int = 0
    perfiles_creados: int = 0
    perfiles_existentes: int = 0
    progreso_nuevo: int = 0
    progreso_actualizado: int = 0
    omitidos: list[str] = field(default_factory=list)


def migrar_usuario(
    db: Session,
    uid: str,
    perfil: dict | None,
    progreso: Iterable[dict],
    resumen: Resumen,
) -> None:
    resumen.usuarios += 1

    # Perfil
    existente = db.get(Perfil, uid)
    if existente is not None:
        resumen.perfiles_existentes += 1
    else:
        try:
            p = convertir_perfil(perfil or {})
        except ValidationError as e:
            resumen.omitidos.append(f"{uid}: perfil inválido ({e.errors()[0]['loc']})")
            return
        db.add(Perfil(uid=uid, **p.model_dump()))
        db.flush()
        resumen.perfiles_creados += 1

    # Progreso (gana el mayor avance)
    for i, doc in enumerate(progreso):
        try:
            it = convertir_progreso(doc)
        except (ValidationError, TypeError, ValueError) as e:
            resumen.omitidos.append(f"{uid}: progreso #{i} inválido ({e.__class__.__name__})")
            continue
        clave = (uid, it.grado, it.materia, it.actividad)
        fila = db.get(Progreso, clave)
        if fila is None:
            db.add(Progreso(uid=uid, grado=it.grado, materia=it.materia,
                            actividad=it.actividad, porcentaje=it.porcentaje,
                            intentos=it.intentos, ultima_vez=it.ultima_vez))
            resumen.progreso_nuevo += 1
        else:
            cambio = False
            if it.porcentaje > fila.porcentaje:
                fila.porcentaje = it.porcentaje
                fila.ultima_vez = it.ultima_vez or fila.ultima_vez
                cambio = True
            if it.intentos > fila.intentos:
                fila.intentos = it.intentos
                cambio = True
            if cambio:
                resumen.progreso_actualizado += 1
        db.flush()


# ── Lectura de Firestore ─────────────────────────────────────────────────────

def leer_firestore(solo_uid: str | None) -> Iterator[tuple[str, dict, list[dict]]]:
    import firebase_admin  # import tardío: solo hace falta al migrar de verdad
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.ApplicationDefault(),
            {"projectId": os.environ.get("FIREBASE_PROJECT_ID", "rag-numi")},
        )
    fs = firestore.client()
    docs = ([fs.collection("usuarios").document(solo_uid).get()]
            if solo_uid else fs.collection("usuarios").stream())
    for d in docs:
        if not d.exists:
            continue
        progreso = [p.to_dict() for p in d.reference.collection("progreso").stream()]
        yield d.id, d.to_dict() or {}, progreso


# ── Programa principal ───────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--dry-run", action="store_true", help="No escribe; solo informa")
    ap.add_argument("--uid", help="Migrar solo esta cuenta")
    args = ap.parse_args()

    if not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        print("Falta GOOGLE_APPLICATION_CREDENTIALS (ruta a la clave de servicio de Firebase).")
        return 2

    from app.users.database import SessionLocal, engine, init_db

    print(f"Destino: {engine.url.render_as_string(hide_password=True)}")
    init_db()
    resumen = Resumen()
    db = SessionLocal()
    try:
        for uid, perfil, progreso in leer_firestore(args.uid):
            migrar_usuario(db, uid, perfil, progreso, resumen)
        if args.dry_run:
            db.rollback()
        else:
            db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

    modo = "SIMULACIÓN (no se escribió nada)" if args.dry_run else "LISTO"
    print(f"\n{modo}")
    print(f"  cuentas leídas:        {resumen.usuarios}")
    print(f"  perfiles creados:      {resumen.perfiles_creados}")
    print(f"  perfiles ya existían:  {resumen.perfiles_existentes}")
    print(f"  progreso nuevo:        {resumen.progreso_nuevo}")
    print(f"  progreso actualizado:  {resumen.progreso_actualizado}")
    if resumen.omitidos:
        print(f"  omitidos ({len(resumen.omitidos)}):")
        for o in resumen.omitidos[:20]:
            print(f"    - {o}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

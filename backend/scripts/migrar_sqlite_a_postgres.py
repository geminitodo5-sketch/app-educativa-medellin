"""Migración ÚNICA: copia perfiles y progreso de una base SQLite existente
(la que usaba el backend antes de tener PostgreSQL) hacia PostgreSQL.

No hace falta si la base de datos en Railway todavía está vacía — en ese caso
basta con apuntar USERS_DATABASE_URL a Postgres y redesplegar; las tablas se
crean solas. Este script es para cuando YA hay usuarios reales guardados en el
archivo SQLite (por ejemplo, si el backend corrió un tiempo con un volumen).

Es seguro repetirlo: usa la misma fusión que el resto de la app (gana el
mayor avance) y nunca sobrescribe un perfil que el destino ya tenga.

Uso (ver backend/README.md, sección "Migrar de SQLite a PostgreSQL"):
    python scripts/migrar_sqlite_a_postgres.py ^
        --origen sqlite:///C:/ruta/a/usuarios.db ^
        --destino postgresql+psycopg://usuario:clave@host:puerto/basededatos ^
        --dry-run

    (sin --dry-run para escribir de verdad)
"""

from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402

from app.users.database import Base, _crear_engine  # noqa: E402
from app.users.models import Perfil, Progreso  # noqa: E402
from scripts.migrar_firestore import Resumen  # noqa: E402


def migrar(origen_url: str, destino_url: str, dry_run: bool) -> Resumen:
    resumen = Resumen()

    origen_engine = _crear_engine(origen_url)
    destino_engine = _crear_engine(destino_url)
    Base.metadata.create_all(destino_engine)

    SesionOrigen = sessionmaker(bind=origen_engine)
    SesionDestino = sessionmaker(bind=destino_engine)

    src = SesionOrigen()
    dst = SesionDestino()
    try:
        perfiles = src.scalars(select(Perfil)).all()
        for p in perfiles:
            resumen.usuarios += 1
            existente = dst.get(Perfil, p.uid)
            if existente is not None:
                resumen.perfiles_existentes += 1
            else:
                dst.add(Perfil(
                    uid=p.uid, nombre=p.nombre, grado=p.grado,
                    personaje=p.personaje, email=p.email, edad=p.edad,
                    genero=p.genero, fecha_registro=p.fecha_registro,
                ))
                dst.flush()
                resumen.perfiles_creados += 1

            registros = src.scalars(
                select(Progreso).where(Progreso.uid == p.uid)
            ).all()
            for r in registros:
                clave = (r.uid, r.grado, r.materia, r.actividad)
                fila = dst.get(Progreso, clave)
                if fila is None:
                    dst.add(Progreso(
                        uid=r.uid, grado=r.grado, materia=r.materia,
                        actividad=r.actividad, porcentaje=r.porcentaje,
                        intentos=r.intentos, ultima_vez=r.ultima_vez,
                    ))
                    resumen.progreso_nuevo += 1
                else:
                    cambio = False
                    if r.porcentaje > fila.porcentaje:
                        fila.porcentaje = r.porcentaje
                        fila.ultima_vez = r.ultima_vez or fila.ultima_vez
                        cambio = True
                    if r.intentos > fila.intentos:
                        fila.intentos = r.intentos
                        cambio = True
                    if cambio:
                        resumen.progreso_actualizado += 1
                dst.flush()

        if dry_run:
            dst.rollback()
        else:
            dst.commit()
    except Exception:
        dst.rollback()
        raise
    finally:
        src.close()
        dst.close()

    return resumen


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--origen", required=True,
                     help="URL SQLAlchemy de la base SQLite actual, "
                          "p. ej. sqlite:///C:/ruta/a/usuarios.db")
    ap.add_argument("--destino", required=True,
                     help="URL SQLAlchemy de PostgreSQL destino")
    ap.add_argument("--dry-run", action="store_true", help="No escribe; solo informa")
    args = ap.parse_args()

    if not args.origen.startswith("sqlite:"):
        print("Aviso: --origen no parece SQLite; continúo igual.")

    print(f"Origen:  {args.origen}")
    print(f"Destino: {args.destino.split('@')[-1] if '@' in args.destino else args.destino}")

    resumen = migrar(args.origen, args.destino, args.dry_run)

    modo = "SIMULACIÓN (no se escribió nada)" if args.dry_run else "LISTO"
    print(f"\n{modo}")
    print(f"  cuentas leídas:        {resumen.usuarios}")
    print(f"  perfiles creados:      {resumen.perfiles_creados}")
    print(f"  perfiles ya existían:  {resumen.perfiles_existentes}")
    print(f"  progreso nuevo:        {resumen.progreso_nuevo}")
    print(f"  progreso actualizado:  {resumen.progreso_actualizado}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

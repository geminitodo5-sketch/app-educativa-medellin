"""Servicio de USUARIOS: perfil y progreso del estudiante autenticado.

Todas las rutas operan sobre `/api/v1/me`: el dueño de los datos es siempre el
uid del token verificado, no un parámetro del cliente.
"""

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth import usuario_actual
from app.ratelimit import limitar_usuarios
from app.users.database import get_db
from app.users.models import Perfil, Progreso
from app.users.schemas import PerfilIn, PerfilOut, ProgresoItem, ProgresoLote

router = APIRouter(
    prefix="/api/v1/me",
    tags=["usuario"],
    dependencies=[Depends(limitar_usuarios)],
)


@router.get("/perfil", response_model=PerfilOut)
def obtener_perfil(uid: str = Depends(usuario_actual), db: Session = Depends(get_db)):
    perfil = db.get(Perfil, uid)
    if perfil is None:
        # "codigo" permite al cliente distinguir "cuenta sin perfil" de una ruta
        # inexistente (p. ej. un servidor viejo que también responde 404).
        raise HTTPException(
            404,
            {"codigo": "perfil_no_existe", "mensaje": "El usuario aún no tiene perfil."},
        )
    return perfil


@router.put("/perfil", response_model=PerfilOut)
def guardar_perfil(
    datos: PerfilIn, uid: str = Depends(usuario_actual), db: Session = Depends(get_db)
):
    perfil = db.get(Perfil, uid)
    if perfil is None:
        perfil = Perfil(uid=uid, **datos.model_dump())
        db.add(perfil)
    else:
        for campo, valor in datos.model_dump().items():
            setattr(perfil, campo, valor)
    db.commit()
    return perfil


@router.get("/progreso", response_model=list[ProgresoItem])
def listar_progreso(uid: str = Depends(usuario_actual), db: Session = Depends(get_db)):
    return db.scalars(select(Progreso).where(Progreso.uid == uid)).all()


@router.put("/progreso", response_model=list[ProgresoItem])
def guardar_progreso(
    lote: ProgresoLote, uid: str = Depends(usuario_actual), db: Session = Depends(get_db)
):
    """Upsert en lote. Regla de fusión: gana el mayor avance (igual que el cliente).

    Devuelve el estado final del servidor para los registros enviados.
    """
    if db.get(Perfil, uid) is None:
        raise HTTPException(409, "Crea el perfil antes de subir progreso.")

    resultado: dict[tuple, Progreso] = {}
    for it in lote.items:
        clave = (uid, it.grado, it.materia, it.actividad)
        fila = resultado.get(clave) or db.get(Progreso, clave)
        if fila is None:
            fila = Progreso(
                uid=uid, grado=it.grado, materia=it.materia, actividad=it.actividad,
                porcentaje=it.porcentaje, intentos=it.intentos, ultima_vez=it.ultima_vez,
            )
            db.add(fila)
        else:
            if it.porcentaje >= fila.porcentaje:
                fila.porcentaje = it.porcentaje
                fila.ultima_vez = it.ultima_vez or fila.ultima_vez
            fila.intentos = max(fila.intentos, it.intentos)
        resultado[clave] = fila
    db.commit()
    return list(resultado.values())


@router.delete("", status_code=204)
def borrar_mis_datos(uid: str = Depends(usuario_actual), db: Session = Depends(get_db)):
    """Elimina el perfil y todo el progreso del usuario (derecho de supresión)."""
    perfil = db.get(Perfil, uid)
    if perfil is not None:
        db.delete(perfil)
        db.commit()
    return Response(status_code=204)

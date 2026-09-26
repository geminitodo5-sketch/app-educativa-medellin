from sqlalchemy import select

from app.users import database
from app.users.models import Perfil, Progreso
from scripts.migrar_firestore import (
    Resumen, convertir_perfil, convertir_progreso, migrar_usuario,
)


def _db():
    database.init_db()
    database.Base.metadata.drop_all(database.engine)
    database.init_db()
    return database.SessionLocal()


def test_convierte_lo_que_guardaba_firestore():
    p = convertir_perfil({"nombre": "Luis", "grado": 1.0, "personaje": "pollito",
                          "email": "a@b.co", "edad": 8.0, "genero": "Masculino",
                          "fecha_registro": "2026-04-01T10:00:00"})
    assert (p.nombre, p.grado, p.edad) == ("Luis", 1, 8)
    it = convertir_progreso({"grado": 3, "materia": "español", "actividad": "¿Vivo o no Vivo?",
                             "porcentaje": 140, "intentos": 2})
    assert it.porcentaje == 100.0 and it.materia == "español"


def test_migra_y_es_idempotente_y_gana_el_mayor_avance():
    db = _db()
    perfil = {"nombre": "Luis", "grado": 1, "personaje": "pollito"}
    prog = [{"grado": 1, "materia": "ciencias", "actividad": "A", "porcentaje": 60, "intentos": 2},
            {"grado": 1, "materia": "ingles", "actividad": "B", "porcentaje": 100, "intentos": 1}]

    r1 = Resumen()
    migrar_usuario(db, "uid-1", perfil, prog, r1)
    db.commit()
    assert (r1.perfiles_creados, r1.progreso_nuevo) == (1, 2)

    # Repetir no duplica ni cambia nada
    r2 = Resumen()
    migrar_usuario(db, "uid-1", perfil, prog, r2)
    db.commit()
    assert (r2.perfiles_creados, r2.progreso_nuevo, r2.progreso_actualizado) == (0, 0, 0)
    assert len(db.scalars(select(Progreso)).all()) == 2

    # Un avance mayor sí actualiza; uno menor no baja el guardado
    r3 = Resumen()
    migrar_usuario(db, "uid-1", perfil, [
        {"grado": 1, "materia": "ciencias", "actividad": "A", "porcentaje": 90, "intentos": 1},
        {"grado": 1, "materia": "ingles", "actividad": "B", "porcentaje": 10, "intentos": 1},
    ], r3)
    db.commit()
    a = db.get(Progreso, ("uid-1", 1, "ciencias", "A"))
    b = db.get(Progreso, ("uid-1", 1, "ingles", "B"))
    assert (a.porcentaje, a.intentos) == (90, 2)
    assert b.porcentaje == 100


def test_no_pisa_un_perfil_que_ya_existe_en_el_servidor():
    db = _db()
    db.add(Perfil(uid="uid-2", nombre="Nuevo", grado=4, personaje="mono"))
    db.commit()
    r = Resumen()
    migrar_usuario(db, "uid-2", {"nombre": "Viejo", "grado": 1, "personaje": "pollito"}, [], r)
    db.commit()
    assert r.perfiles_existentes == 1
    assert db.get(Perfil, "uid-2").nombre == "Nuevo"


def test_omite_registros_invalidos_sin_abortar():
    db = _db()
    r = Resumen()
    migrar_usuario(db, "uid-3", {"nombre": "X", "grado": 2, "personaje": "p"}, [
        {"grado": 99, "materia": "ciencias", "actividad": "A", "porcentaje": 5},   # grado inválido
        {"grado": 2, "materia": "ciencias", "actividad": "OK", "porcentaje": 5},
    ], r)
    db.commit()
    assert r.progreso_nuevo == 1 and len(r.omitidos) == 1

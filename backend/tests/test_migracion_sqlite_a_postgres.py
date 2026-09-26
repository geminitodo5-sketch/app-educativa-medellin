"""Prueba migrar_sqlite_a_postgres.py con dos SQLite (origen y destino): la
función migrar() es la misma sin importar el motor real, así que esto cubre
el mismo código que se ejecuta contra PostgreSQL de verdad.
"""

import os
import tempfile

from sqlalchemy.orm import sessionmaker

from app.users.database import Base, _crear_engine
from app.users.models import Perfil, Progreso
from scripts.migrar_sqlite_a_postgres import migrar


def _sqlite_con_datos(tmp_path, perfiles):
    """Crea un SQLite nuevo y le carga perfiles: [(uid, [progreso...])]."""
    url = f"sqlite:///{tmp_path}"
    eng = _crear_engine(url)
    Base.metadata.create_all(eng)
    Sesion = sessionmaker(bind=eng)
    db = Sesion()
    for uid, nombre, grado, progresos in perfiles:
        db.add(Perfil(uid=uid, nombre=nombre, grado=grado, personaje="pollito"))
        for p in progresos:
            db.add(Progreso(uid=uid, **p))
    db.commit()
    db.close()
    eng.dispose()
    return url


def _leer_todo(url):
    eng = _crear_engine(url)
    Sesion = sessionmaker(bind=eng)
    db = Sesion()
    perfiles = {p.uid: p for p in db.query(Perfil).all()}
    progreso = {(p.uid, p.grado, p.materia, p.actividad): p
                for p in db.query(Progreso).all()}
    db.close()
    eng.dispose()
    return perfiles, progreso


def test_copia_perfil_y_progreso(tmp_path):
    origen = _sqlite_con_datos(tmp_path / "origen.db", [
        ("uid-1", "Luis", 3, [
            {"grado": 3, "materia": "ciencias", "actividad": "A",
             "porcentaje": 80, "intentos": 2},
        ]),
    ])
    destino = f"sqlite:///{tmp_path / 'destino.db'}"

    resumen = migrar(origen, destino, dry_run=False)
    assert (resumen.perfiles_creados, resumen.progreso_nuevo) == (1, 1)

    perfiles, progreso = _leer_todo(destino)
    assert perfiles["uid-1"].nombre == "Luis"
    assert progreso[("uid-1", 3, "ciencias", "A")].porcentaje == 80


def test_es_repetible_sin_duplicar(tmp_path):
    origen = _sqlite_con_datos(tmp_path / "origen.db", [
        ("uid-1", "Luis", 3, [
            {"grado": 3, "materia": "ciencias", "actividad": "A",
             "porcentaje": 80, "intentos": 2},
        ]),
    ])
    destino = f"sqlite:///{tmp_path / 'destino.db'}"

    migrar(origen, destino, dry_run=False)
    resumen2 = migrar(origen, destino, dry_run=False)

    assert (resumen2.perfiles_creados, resumen2.progreso_nuevo) == (0, 0)
    assert resumen2.perfiles_existentes == 1
    perfiles, progreso = _leer_todo(destino)
    assert len(perfiles) == 1 and len(progreso) == 1


def test_gana_el_mayor_avance_sin_retroceder(tmp_path):
    destino = f"sqlite:///{tmp_path / 'destino.db'}"

    origen1 = _sqlite_con_datos(tmp_path / "o1.db", [
        ("uid-1", "Luis", 3, [
            {"grado": 3, "materia": "ciencias", "actividad": "A",
             "porcentaje": 80, "intentos": 2},
        ]),
    ])
    migrar(origen1, destino, dry_run=False)

    # Un origen distinto con MENOS avance no debe hacer retroceder el destino.
    origen2 = _sqlite_con_datos(tmp_path / "o2.db", [
        ("uid-1", "Luis", 3, [
            {"grado": 3, "materia": "ciencias", "actividad": "A",
             "porcentaje": 30, "intentos": 9},
        ]),
    ])
    migrar(origen2, destino, dry_run=False)

    _, progreso = _leer_todo(destino)
    fila = progreso[("uid-1", 3, "ciencias", "A")]
    assert fila.porcentaje == 80          # no retrocedió
    assert fila.intentos == 9             # pero sí tomó el mayor de intentos


def test_no_pisa_un_perfil_que_ya_existe_en_destino(tmp_path):
    origen = _sqlite_con_datos(tmp_path / "origen.db", [
        ("uid-1", "Nombre viejo", 1, []),
    ])
    destino_path = tmp_path / "destino.db"
    destino = f"sqlite:///{destino_path}"
    # El destino ya tiene un perfil real para ese uid.
    _sqlite_con_datos(destino_path, [("uid-1", "Nombre real", 5, [])])

    resumen = migrar(origen, destino, dry_run=False)
    assert resumen.perfiles_existentes == 1

    perfiles, _ = _leer_todo(destino)
    assert perfiles["uid-1"].nombre == "Nombre real"


def test_dry_run_no_escribe_nada(tmp_path):
    origen = _sqlite_con_datos(tmp_path / "origen.db", [
        ("uid-1", "Luis", 3, [
            {"grado": 3, "materia": "ciencias", "actividad": "A",
             "porcentaje": 80, "intentos": 2},
        ]),
    ])
    destino_path = tmp_path / "destino.db"
    destino = f"sqlite:///{destino_path}"
    # Crear el esquema vacío para poder leerlo después sin fallar.
    eng = _crear_engine(destino)
    Base.metadata.create_all(eng)
    eng.dispose()

    resumen = migrar(origen, destino, dry_run=True)
    assert resumen.perfiles_creados == 1  # se contó, pero no se guardó

    perfiles, progreso = _leer_todo(destino)
    assert perfiles == {} and progreso == {}

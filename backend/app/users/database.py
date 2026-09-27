"""Conexión a la base de datos de USUARIOS (perfil y progreso).

Es una base de datos distinta de la del contenido: el contenido educativo vive
en archivos de solo lectura (knowledge_base/) y aquí solo hay datos personales.
Un compromiso del servicio de contenido no da acceso a esta base y viceversa.
"""

import os

from sqlalchemy import create_engine, event
from sqlalchemy.engine import make_url
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app import config


class Base(DeclarativeBase):
    pass


def _crear_engine(url: str):
    u = make_url(url)
    es_sqlite = u.get_backend_name() == "sqlite"
    kwargs: dict = {"pool_pre_ping": True}
    if es_sqlite:
        kwargs["connect_args"] = {"check_same_thread": False}
        if u.database and u.database != ":memory:":
            os.makedirs(os.path.dirname(os.path.abspath(u.database)), exist_ok=True)
    eng = create_engine(url, **kwargs)
    if es_sqlite:
        @event.listens_for(eng, "connect")
        def _pragmas(conn, _registro):
            cur = conn.cursor()
            cur.execute("PRAGMA foreign_keys=ON")
            cur.execute("PRAGMA journal_mode=WAL")
            cur.close()
    return eng


engine = _crear_engine(config.USERS_DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

# Diagnóstico de arranque: nunca imprime usuario ni contraseña, solo confirma
# a qué motor y host se conectó realmente el proceso. Útil para detectar un
# USERS_DATABASE_URL que no se aplicó (p. ej. cayó de vuelta a SQLite).
print(
    f"[DB] usuarios → backend={engine.url.get_backend_name()} "
    f"host={engine.url.host or '(sin host: archivo local)'} "
    f"db={engine.url.database}"
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    from app.users import models  # noqa: F401  (registra las tablas)
    Base.metadata.create_all(engine)
    print(f"[DB] tablas listas: {sorted(Base.metadata.tables.keys())}")

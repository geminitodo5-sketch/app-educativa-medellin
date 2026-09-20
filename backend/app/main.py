"""Punto de entrada del backend de Numi.

Dos servicios con responsabilidades y almacenamiento separados:
  • app.content — contenido educativo + IA. Público, solo lectura, sin datos personales.
  • app.users   — perfil y progreso. Autenticado (Firebase), con su propia base de datos.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app import config
from app.content import router as content
from app.users import router as users
from app.users.database import init_db


@asynccontextmanager
async def lifespan(_app: FastAPI):
    init_db()
    await content.startup()
    yield
    await content.shutdown()


app = FastAPI(
    title="Numi API",
    description="Backend de la app educativa Numi: contenido/IA y datos de usuario.",
    version="4.0.0",
    lifespan=lifespan,
    docs_url="/docs" if config.EXPONER_DOCS else None,
    redoc_url=None,
    openapi_url="/openapi.json" if config.EXPONER_DOCS else None,
)

if config.CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=config.CORS_ORIGINS,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )


@app.middleware("http")
async def cabeceras_seguridad(request: Request, call_next):
    resp = await call_next(request)
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["X-Frame-Options"] = "DENY"
    resp.headers["Referrer-Policy"] = "no-referrer"
    if request.url.path.startswith("/api/v1/"):
        resp.headers["Cache-Control"] = "no-store"
    return resp


app.include_router(content.router)
app.include_router(users.router)


@app.get("/", tags=["info"])
def root():
    return {
        "api": "Numi API",
        "version": app.version,
        "servicios": {
            "contenido": "público · /api/paquetes, /api/buscar_semantico, /api/preguntar",
            "usuarios": "autenticado (Bearer Firebase) · /api/v1/me/perfil, /api/v1/me/progreso",
        },
    }


@app.get("/salud", tags=["info"])
def salud():
    return {"estado": "ok"}

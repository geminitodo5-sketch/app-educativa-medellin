"""
RAG API — App Educativa Numi
API pública para descarga de bases de conocimiento offline.
"""

import json
import os
import zipfile
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="RAG API — Numi Educativa",
    description=(
        "API pública para descargar bases de conocimiento de las 5 materias. "
        "Una vez descargados, los paquetes funcionan 100% offline en la app Numi."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
KNOWLEDGE_DIR = os.path.join(BASE_DIR, "knowledge_base")
PACKAGES_DIR = os.path.join(BASE_DIR, "packages")

MATERIAS = {"matematicas", "ingles", "espanol", "ciencias", "sociales"}

os.makedirs(PACKAGES_DIR, exist_ok=True)


def _json_path(materia: str) -> str:
    return os.path.join(KNOWLEDGE_DIR, f"{materia}.json")


def _build_zip(materia: str) -> str:
    """Genera (o regenera) el ZIP para una materia y devuelve su ruta."""
    src = _json_path(materia)
    if not os.path.exists(src):
        raise FileNotFoundError(materia)
    dst = os.path.join(PACKAGES_DIR, f"rag_{materia}.zip")
    src_mtime = os.path.getmtime(src)
    dst_mtime = os.path.getmtime(dst) if os.path.exists(dst) else 0
    if src_mtime > dst_mtime:
        with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.write(src, arcname=f"{materia}.json")
    return dst


def _load(materia: str) -> dict:
    with open(_json_path(materia), encoding="utf-8") as f:
        return json.load(f)


# ── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/", tags=["info"])
def root():
    return {
        "api": "RAG API — Numi Educativa",
        "version": "1.0.0",
        "materias_disponibles": sorted(MATERIAS),
        "endpoints": {
            "listar_paquetes": "/api/paquetes",
            "info_paquete":    "/api/paquetes/{materia}/info",
            "descargar_zip":   "/api/paquetes/{materia}",
        },
    }


@app.get("/api/paquetes", tags=["paquetes"])
def listar_paquetes():
    """Lista todos los paquetes disponibles con su metadata."""
    resultado = []
    for materia in sorted(MATERIAS):
        path = _json_path(materia)
        if not os.path.exists(path):
            continue
        data = _load(materia)
        contenido = data.get("contenido", [])
        resultado.append({
            "materia": materia,
            "version": data.get("version", "1.0.0"),
            "descripcion": data.get("descripcion", ""),
            "total_entradas": len(contenido),
            "grados": sorted({e["grado"] for e in contenido}),
            "url_info":      f"/api/paquetes/{materia}/info",
            "url_descarga":  f"/api/paquetes/{materia}",
        })
    return {"total": len(resultado), "paquetes": resultado}


@app.get("/api/paquetes/{materia}/info", tags=["paquetes"])
def info_paquete(materia: str):
    """Devuelve metadata del paquete sin descargarlo."""
    materia = materia.lower()
    if materia not in MATERIAS:
        raise HTTPException(404, f"Materia '{materia}' no encontrada. "
                                 f"Disponibles: {sorted(MATERIAS)}")
    if not os.path.exists(_json_path(materia)):
        raise HTTPException(404, "Base de conocimiento no encontrada en el servidor.")
    data = _load(materia)
    contenido = data.get("contenido", [])
    temas = sorted({e.get("tema", "") for e in contenido})
    grados = sorted({e["grado"] for e in contenido})
    return {
        "materia": materia,
        "version": data.get("version", "1.0.0"),
        "descripcion": data.get("descripcion", ""),
        "total_entradas": len(contenido),
        "grados": grados,
        "temas": temas,
    }


@app.get("/api/paquetes/{materia}", tags=["paquetes"])
def descargar_paquete(materia: str):
    """
    Descarga el paquete ZIP de una materia.
    El ZIP contiene un archivo JSON con toda la base de conocimiento offline.
    """
    materia = materia.lower()
    if materia not in MATERIAS:
        raise HTTPException(404, f"Materia '{materia}' no encontrada. "
                                 f"Disponibles: {sorted(MATERIAS)}")
    try:
        zip_path = _build_zip(materia)
    except FileNotFoundError:
        raise HTTPException(404, "Base de conocimiento no disponible en el servidor.")

    return FileResponse(
        path=zip_path,
        media_type="application/zip",
        filename=f"rag_{materia}.zip",
        headers={"Content-Disposition": f'attachment; filename="rag_{materia}.zip"'},
    )

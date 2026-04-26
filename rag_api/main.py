"""
RAG API — App Educativa Numi  v2.1.0
API pública para descarga de bases de conocimiento offline.
Búsqueda semántica con FAISS + fastembed (ONNX, sin PyTorch) cuando los
paquetes ML están instalados; los endpoints de descarga siempre funcionan.
"""

import json
import os
import zipfile
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ── ML opcional (FAISS + fastembed) ──────────────────────────────────────────
try:
    import numpy as np
    from fastembed import TextEmbedding
    import faiss as _faiss
    _ML_AVAILABLE = True
except Exception:
    _ML_AVAILABLE = False

# ── Rutas ─────────────────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
KNOWLEDGE_DIR = os.path.join(BASE_DIR, "knowledge_base")
PACKAGES_DIR = os.path.join(BASE_DIR, "packages")
MATERIAS = {"matematicas", "ingles", "espanol", "ciencias", "sociales"}

os.makedirs(PACKAGES_DIR, exist_ok=True)

# ── Estado global FAISS ───────────────────────────────────────────────────────
_model = None          # instancia TextEmbedding (fastembed)
_indexes: dict = {}    # materia → {"index": faiss.Index, "entries": list, "mtime": float}


# ── Helpers de archivos ───────────────────────────────────────────────────────

def _json_path(materia: str) -> str:
    return os.path.join(KNOWLEDGE_DIR, f"{materia}.json")


def _load_json(materia: str) -> dict:
    with open(_json_path(materia), encoding="utf-8") as f:
        return json.load(f)


def _build_zip(materia: str) -> str:
    """Genera (o reutiliza) el ZIP de una materia; devuelve la ruta."""
    src = _json_path(materia)
    if not os.path.exists(src):
        raise FileNotFoundError(materia)
    dst = os.path.join(PACKAGES_DIR, f"rag_{materia}.zip")
    if os.path.getmtime(src) > (os.path.getmtime(dst) if os.path.exists(dst) else 0):
        with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.write(src, arcname=f"{materia}.json")
    return dst


# ── FAISS index builder ───────────────────────────────────────────────────────

def _build_faiss_index(materia: str, model) -> dict:
    """Construye un índice FAISS coseno para una materia usando fastembed."""
    src = _json_path(materia)
    if not os.path.exists(src):
        return {}
    mtime = os.path.getmtime(src)
    data = _load_json(materia)
    entries = data.get("contenido", [])
    if not entries:
        return {}

    texts = [
        f"{e.get('pregunta', '')} {e.get('respuesta', '')} "
        f"{' '.join(e.get('palabras_clave', []))}"
        for e in entries
    ]

    # fastembed devuelve un generador de numpy arrays
    embeddings = np.array(list(model.embed(texts)), dtype=np.float32)
    # Normalización L2 en-lugar para que IndexFlatIP == similitud coseno
    _faiss.normalize_L2(embeddings)

    dim = embeddings.shape[1]
    index = _faiss.IndexFlatIP(dim)
    index.add(embeddings)

    return {"index": index, "entries": entries, "mtime": mtime, "dim": dim}


def _maybe_rebuild(materia: str) -> None:
    """Reconstruye el índice si el JSON cambió desde la última vez."""
    if not _ML_AVAILABLE or _model is None:
        return
    src = _json_path(materia)
    if not os.path.exists(src):
        return
    current_mtime = os.path.getmtime(src)
    cached = _indexes.get(materia, {})
    if cached.get("mtime", 0) < current_mtime:
        _indexes[materia] = _build_faiss_index(materia, _model)


# ── Lifespan (startup / shutdown) ────────────────────────────────────────────

@asynccontextmanager
async def lifespan(_app: FastAPI):
    global _model
    if _ML_AVAILABLE:
        try:
            print("[FAISS] Cargando modelo fastembed (ONNX)…")
            _model = TextEmbedding(
                model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
            )
            for materia in MATERIAS:
                print(f"[FAISS] Construyendo índice para {materia}…")
                _indexes[materia] = _build_faiss_index(materia, _model)
            print("[FAISS] Índices listos.")
        except Exception as exc:
            print(f"[FAISS] No se pudo inicializar la búsqueda semántica: {exc}")
            _model = None
    else:
        print("[FAISS] fastembed / faiss no instalados — búsqueda semántica desactivada.")
    yield
    _indexes.clear()
    _model = None


# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="RAG API — Numi Educativa",
    description=(
        "API pública para descargar bases de conocimiento de las 5 materias. "
        "Incluye búsqueda semántica con FAISS + fastembed (ONNX, sin PyTorch). "
        "Los paquetes descargados funcionan 100 % offline en la app Numi."
    ),
    version="2.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ── Modelos Pydantic ──────────────────────────────────────────────────────────

class BusquedaSemanticaRequest(BaseModel):
    pregunta: str
    materia: str
    grado: Optional[int] = None
    top_k: int = 5


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/", tags=["info"])
def root():
    return {
        "api": "RAG API — Numi Educativa",
        "version": "2.1.0",
        "motor_semantico": "FAISS + fastembed (ONNX)",
        "semantica_disponible": _ML_AVAILABLE and bool(_indexes),
        "materias_disponibles": sorted(MATERIAS),
        "endpoints": {
            "listar_paquetes":  "/api/paquetes",
            "info_paquete":     "/api/paquetes/{materia}/info",
            "descargar_zip":    "/api/paquetes/{materia}",
            "buscar_semantico": "POST /api/buscar_semantico",
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
        data = _load_json(materia)
        contenido = data.get("contenido", [])
        resultado.append({
            "materia":        materia,
            "version":        data.get("version", "1.0.0"),
            "descripcion":    data.get("descripcion", ""),
            "total_entradas": len(contenido),
            "grados":         sorted({e["grado"] for e in contenido}),
            "url_info":       f"/api/paquetes/{materia}/info",
            "url_descarga":   f"/api/paquetes/{materia}",
        })
    return {"total": len(resultado), "paquetes": resultado}


@app.get("/api/paquetes/{materia}/info", tags=["paquetes"])
def info_paquete(materia: str):
    """Devuelve metadata del paquete sin descargarlo."""
    materia = materia.lower()
    if materia not in MATERIAS:
        raise HTTPException(404, f"Materia '{materia}' no encontrada. Disponibles: {sorted(MATERIAS)}")
    if not os.path.exists(_json_path(materia)):
        raise HTTPException(404, "Base de conocimiento no encontrada en el servidor.")
    data = _load_json(materia)
    contenido = data.get("contenido", [])
    return {
        "materia":        materia,
        "version":        data.get("version", "1.0.0"),
        "descripcion":    data.get("descripcion", ""),
        "total_entradas": len(contenido),
        "grados":         sorted({e["grado"] for e in contenido}),
        "temas":          sorted({e.get("tema", "") for e in contenido}),
    }


@app.get("/api/paquetes/{materia}", tags=["paquetes"])
def descargar_paquete(materia: str):
    """Descarga el paquete ZIP de una materia para uso offline."""
    materia = materia.lower()
    if materia not in MATERIAS:
        raise HTTPException(404, f"Materia '{materia}' no encontrada. Disponibles: {sorted(MATERIAS)}")
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


@app.post("/api/buscar_semantico", tags=["semantico"])
def buscar_semantico(req: BusquedaSemanticaRequest):
    """
    Búsqueda semántica con FAISS + fastembed (ONNX, sin PyTorch).

    Devuelve los top_k resultados más similares semánticamente a la pregunta.
    Si se especifica `grado`, las entradas de otro grado reciben una penalización.
    """
    if not _ML_AVAILABLE or _model is None:
        raise HTTPException(
            503,
            "Búsqueda semántica no disponible. "
            "El servidor necesita fastembed, faiss-cpu y numpy instalados.",
        )

    materia = req.materia.lower()
    if materia not in MATERIAS:
        raise HTTPException(404, f"Materia '{materia}' no encontrada. Disponibles: {sorted(MATERIAS)}")

    _maybe_rebuild(materia)

    idx_data = _indexes.get(materia)
    if not idx_data or not idx_data.get("index"):
        raise HTTPException(503, f"Índice semántico para '{materia}' no está listo.")

    # Encode de la consulta con fastembed
    query_vec = np.array(list(_model.embed([req.pregunta])), dtype=np.float32)
    _faiss.normalize_L2(query_vec)

    k = min(req.top_k, idx_data["index"].ntotal)
    scores, indices = idx_data["index"].search(query_vec, k)

    entries = idx_data["entries"]
    resultados = []
    for score, idx in zip(scores[0].tolist(), indices[0].tolist()):
        if idx < 0:
            continue
        entry = entries[idx]
        sim = float(score)
        # Penalización leve si el grado no coincide con el solicitado
        if req.grado is not None and entry.get("grado") != req.grado:
            sim *= 0.80
        resultados.append({
            "id":             entry.get("id", ""),
            "grado":          entry.get("grado"),
            "tema":           entry.get("tema", ""),
            "pregunta":       entry.get("pregunta", ""),
            "respuesta":      entry.get("respuesta", ""),
            "palabras_clave": entry.get("palabras_clave", []),
            "similitud":      round(sim, 4),
        })

    resultados.sort(key=lambda x: x["similitud"], reverse=True)

    return {
        "pregunta":   req.pregunta,
        "materia":    materia,
        "grado":      req.grado,
        "resultados": resultados,
        "total":      len(resultados),
    }

"""
RAG API — App Educativa Numi  v3.0.0
API pública para descarga de bases de conocimiento offline.
Búsqueda semántica con FAISS + fastembed (ONNX, sin PyTorch) cuando los
paquetes ML están instalados; los endpoints de descarga siempre funcionan.
Integra Google Gemini (LLM gratuito) para respuestas generativas adaptadas al grado.
"""

import asyncio
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

# ── LLM opcional (Google Gemini — nuevo SDK google-genai) ────────────────────
try:
    from google import genai as _genai
    from google.genai import types as _genai_types
    _GENAI_INSTALLED = True
except ImportError:
    _genai       = None  # type: ignore
    _genai_types = None  # type: ignore
    _GENAI_INSTALLED = False

_GEMINI_KEY        = os.environ.get("GEMINI_API_KEY", "").strip()
_GEMINI_MODEL_NAME = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")
_gemini_client     = None  # inicializado en lifespan si hay API key

# FAISS desactivado por defecto para reducir RAM en Railway free tier (~120 MB menos).
# Actívalo con FAISS_ENABLED=true si tienes suficiente memoria (≥ 512 MB disponibles).
_FAISS_ENABLED = os.environ.get("FAISS_ENABLED", "false").lower() == "true"

# ── Rutas ─────────────────────────────────────────────────────────────────────
BASE_DIR      = os.path.dirname(os.path.abspath(__file__))
KNOWLEDGE_DIR = os.path.join(BASE_DIR, "knowledge_base")
PACKAGES_DIR  = os.path.join(BASE_DIR, "packages")
MATERIAS      = {"matematicas", "ingles", "espanol", "ciencias", "sociales"}

os.makedirs(PACKAGES_DIR, exist_ok=True)

# ── Estado global FAISS ───────────────────────────────────────────────────────
_model   = None       # instancia TextEmbedding (fastembed)
_indexes: dict = {}   # materia → {"index": faiss.Index, "entries": list, "mtime": float}


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
    data  = _load_json(materia)
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

    dim   = embeddings.shape[1]
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


# ── Helper FAISS reutilizable ─────────────────────────────────────────────────

def _buscar_contexto_faiss(
    pregunta: str, materia: str, grado: int, top_k: int = 5
) -> list:
    """
    Búsqueda semántica FAISS.
    Retorna lista de entradas ordenadas por similitud (mayor a menor).
    Las entradas de grado distinto reciben una penalización del 20 %.
    """
    if not _ML_AVAILABLE or _model is None:
        return []

    _maybe_rebuild(materia)
    idx_data = _indexes.get(materia)
    if not idx_data or not idx_data.get("index"):
        return []

    query_vec = np.array(list(_model.embed([pregunta])), dtype=np.float32)
    _faiss.normalize_L2(query_vec)

    k = min(top_k, idx_data["index"].ntotal)
    scores, indices = idx_data["index"].search(query_vec, k)

    entries    = idx_data["entries"]
    resultados = []
    for score, idx in zip(scores[0].tolist(), indices[0].tolist()):
        if idx < 0:
            continue
        entry = entries[idx]
        sim   = float(score)
        if entry.get("grado") != grado:
            sim *= 0.80
        resultados.append({**entry, "similitud": round(sim, 4)})

    resultados.sort(key=lambda x: x["similitud"], reverse=True)
    return resultados


# ── Búsqueda JSON directa (fallback sin ML) ──────────────────────────────────

def _buscar_contexto_json(
    pregunta: str, materia: str, grado: int, top_k: int = 5
) -> list:
    """
    Búsqueda por palabras clave directamente en el JSON.
    No requiere fastembed ni FAISS — consume muy poca RAM.
    Usada cuando FAISS no está habilitado o no está listo.
    """
    try:
        data    = _load_json(materia)
        entries = data.get("contenido", [])
    except Exception:
        return []

    _stop = {
        'que','como','cual','para','por','los','las','del','una','con',
        'son','hay','sus','mis','nos','les','ser','fue','era','este',
        'esta','estos','estas','ese','esa','esos','esas','muy','bien',
        'puedo','puede','quiero','dime','favor','hacer',
    }

    def _n(t: str) -> str:
        return (t.lower()
                .replace('á','a').replace('é','e').replace('í','i')
                .replace('ó','o').replace('ú','u').replace('ñ','n'))

    tokens = {w for w in _n(pregunta).split() if len(w) >= 3 and w not in _stop}

    # Sin tokens útiles → devuelve entradas del grado como contexto base
    if not tokens:
        base = [e for e in entries if e.get("grado") == grado][:top_k]
        return [{**e, "similitud": 0.05} for e in base]

    scored = []
    for entry in entries:
        text = _n(
            f"{entry.get('pregunta','')} {entry.get('respuesta','')} "
            f"{' '.join(entry.get('palabras_clave', []))}"
        )
        hits = sum(1 for t in tokens if t in text)
        if hits == 0:
            continue
        sim = hits / len(tokens)
        if entry.get("grado") != grado:
            sim *= 0.80
        scored.append({**entry, "similitud": round(sim, 4)})

    scored.sort(key=lambda x: x["similitud"], reverse=True)

    if not scored:
        base = [e for e in entries if e.get("grado") == grado][:top_k]
        return [{**e, "similitud": 0.05} for e in base]

    return scored[:top_k]


# ── Prompt para Gemini ────────────────────────────────────────────────────────

def _construir_prompt(
    pregunta: str, materia: str, grado: int, contexto: list
) -> str:
    """Construye el prompt completo (sistema + contexto + pregunta) para Gemini."""
    nombres_materia = {
        "matematicas": "Matemáticas",
        "ciencias":    "Ciencias Naturales",
        "espanol":     "Español y Literatura",
        "ingles":      "Inglés",
        "sociales":    "Ciencias Sociales",
    }
    nombre_materia = nombres_materia.get(materia, materia.title())

    # Inglés: responde principalmente en inglés
    if materia == "ingles":
        idioma_inst = (
            "Respond primarily in English since this is an English class. "
            "You may add a brief Spanish clarification for very difficult words."
        )
    else:
        idioma_inst = "Responde SIEMPRE en español."

    # Configuración por grado: (descripción del nivel, longitud, tono)
    config_grado = {
        3: (
            "un niño o niña de 8-9 años en tercer grado de primaria",
            "máximo 3 oraciones muy simples y fáciles de entender",
            "muy amigable, cálido y motivador — puedes usar 1 o 2 emojis si ayudan",
        ),
        4: (
            "un niño o niña de 9-10 años en cuarto grado de primaria",
            "máximo 4 oraciones claras y directas",
            "amigable, positivo y alentador",
        ),
        5: (
            "un estudiante de 10-11 años en quinto grado de primaria",
            "máximo 5 oraciones bien estructuradas",
            "respetuoso, claro y motivador",
        ),
    }
    nivel, longitud, tono = config_grado.get(grado, config_grado[5])

    # Construir bloque de contexto con las 3 entradas más relevantes
    bloques = []
    for i, c in enumerate(contexto[:3], 1):
        tema  = c.get("tema", "")
        resp  = c.get("respuesta", "")
        sim   = c.get("similitud", 0)
        if resp:
            bloques.append(
                f"[Fuente {i} | Tema: {tema} | Relevancia: {sim:.2f}]\n{resp}"
            )
    ctx_text = "\n\n".join(bloques) if bloques else "(Sin contexto disponible)"

    return f"""Eres Numi, un asistente educativo para {nivel}.
Tu tono debe ser {tono}.
{idioma_inst}
Tu respuesta debe tener {longitud}.

REGLAS IMPORTANTES:
- Basa tu respuesta PRINCIPALMENTE en el contexto educativo proporcionado abajo.
- Si la información NO está en el contexto, admítelo honestamente con frases como \
"No tengo esa información aquí, pero..." y da una orientación básica.
- NUNCA inventes datos académicos incorrectos (fechas, fórmulas, nombres, conceptos).
- Explica con tus propias palabras adaptadas al nivel del estudiante. \
No copies el contexto textualmente.
- Si el contexto no es relevante para la pregunta, dilo amablemente y sugiere \
reformularla.

CONTEXTO EDUCATIVO ({nombre_materia}, Grado {grado}):
{ctx_text}

PREGUNTA DEL ESTUDIANTE: {pregunta}

RESPUESTA:"""


# ── Inicialización FAISS en background ───────────────────────────────────────

async def _init_faiss_background() -> None:
    """Carga el modelo fastembed y construye índices FAISS sin bloquear el startup."""
    global _model
    if not _ML_AVAILABLE:
        print("[FAISS] fastembed / faiss no instalados — búsqueda semántica desactivada.")
        return
    try:
        print("[FAISS] Cargando modelo fastembed (ONNX) en background…")
        loop = asyncio.get_event_loop()
        _model = await loop.run_in_executor(
            None,
            lambda: TextEmbedding(
                model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
            ),
        )
        for materia in MATERIAS:
            print(f"[FAISS] Construyendo índice para {materia}…")
            idx = await loop.run_in_executor(
                None, lambda m=materia: _build_faiss_index(m, _model)
            )
            _indexes[materia] = idx
        print("[FAISS] Índices listos.")
    except Exception as exc:
        print(f"[FAISS] No se pudo inicializar la búsqueda semántica: {exc}")
        _model = None


# ── Lifespan (startup / shutdown) ────────────────────────────────────────────

@asynccontextmanager
async def lifespan(_app: FastAPI):
    global _gemini_client

    # ── Gemini: inicializar si hay API key ──────────────────────────────────
    if _GENAI_INSTALLED and _GEMINI_KEY:
        try:
            _gemini_client = _genai.Client(api_key=_GEMINI_KEY)
            print(f"[Gemini] Listo con modelo '{_GEMINI_MODEL_NAME}'.")
        except Exception as exc:
            print(f"[Gemini] No se pudo inicializar: {exc}")
            _gemini_client = None
    else:
        if not _GENAI_INSTALLED:
            print("[Gemini] google-genai no instalado — LLM desactivado.")
        else:
            print(
                "[Gemini] GEMINI_API_KEY no configurada — LLM desactivado. "
                "Configura la variable de entorno GEMINI_API_KEY para activarlo."
            )

    # ── FAISS: solo si FAISS_ENABLED=true (desactivado por defecto para ahorrar RAM)
    if _FAISS_ENABLED:
        asyncio.create_task(_init_faiss_background())
    else:
        print("[FAISS] Desactivado (FAISS_ENABLED=false). "
              "Usa FAISS_ENABLED=true para activar búsqueda semántica.")
        print("[FAISS] /api/preguntar usará búsqueda JSON directa (bajo consumo de RAM).")
    yield

    # ── Cleanup ─────────────────────────────────────────────────────────────
    _indexes.clear()
    _model         = None
    _gemini_client = None


# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="RAG API — Numi Educativa",
    description=(
        "API pública para descargar bases de conocimiento de las 5 materias. "
        "Incluye búsqueda semántica FAISS + fastembed (ONNX, sin PyTorch) "
        "y respuestas generativas con Google Gemini (LLM gratuito). "
        "Los paquetes descargados funcionan 100 % offline en la app Numi."
    ),
    version="3.0.0",
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
    materia:  str
    grado:    Optional[int] = None
    top_k:    int = 5


class PreguntaLLMRequest(BaseModel):
    pregunta: str
    materia:  str
    grado:    Optional[int] = 3


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/", tags=["info"])
def root():
    return {
        "api":                  "RAG API — Numi Educativa",
        "version":              "3.0.0",
        "motor_semantico":      "FAISS + fastembed (ONNX)",
        "faiss_habilitado":      _FAISS_ENABLED,
        "semantica_disponible": _ML_AVAILABLE and bool(_indexes),
        "llm_disponible":       _gemini_client is not None,
        "llm_modelo":           _GEMINI_MODEL_NAME if _gemini_client is not None else None,
        "materias_disponibles": sorted(MATERIAS),
        "endpoints": {
            "listar_paquetes":  "/api/paquetes",
            "info_paquete":     "/api/paquetes/{materia}/info",
            "descargar_zip":    "/api/paquetes/{materia}",
            "buscar_semantico": "POST /api/buscar_semantico",
            "preguntar_llm":    "POST /api/preguntar",
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
        data      = _load_json(materia)
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
        raise HTTPException(
            404, f"Materia '{materia}' no encontrada. Disponibles: {sorted(MATERIAS)}"
        )
    if not os.path.exists(_json_path(materia)):
        raise HTTPException(404, "Base de conocimiento no encontrada en el servidor.")
    data      = _load_json(materia)
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
        raise HTTPException(
            404, f"Materia '{materia}' no encontrada. Disponibles: {sorted(MATERIAS)}"
        )
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
        raise HTTPException(
            404, f"Materia '{materia}' no encontrada. Disponibles: {sorted(MATERIAS)}"
        )

    _maybe_rebuild(materia)

    idx_data = _indexes.get(materia)
    if not idx_data or not idx_data.get("index"):
        raise HTTPException(503, f"Índice semántico para '{materia}' no está listo.")

    # Encode de la consulta con fastembed
    query_vec = np.array(list(_model.embed([req.pregunta])), dtype=np.float32)
    _faiss.normalize_L2(query_vec)

    k = min(req.top_k, idx_data["index"].ntotal)
    scores, indices = idx_data["index"].search(query_vec, k)

    entries    = idx_data["entries"]
    resultados = []
    for score, idx in zip(scores[0].tolist(), indices[0].tolist()):
        if idx < 0:
            continue
        entry = entries[idx]
        sim   = float(score)
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


@app.post("/api/preguntar", tags=["llm"])
async def preguntar(req: PreguntaLLMRequest):
    """
    Endpoint LLM: búsqueda semántica FAISS + Google Gemini → respuesta natural.

    Flujo:
      1. Recupera contexto relevante con FAISS (top-5, penalización por grado).
      2. Construye un prompt con system-instructions adaptadas al grado y materia.
      3. Gemini genera la respuesta final en lenguaje apropiado para el niño.
      4. Fallback automático a la respuesta RAG cruda si Gemini falla o no está configurado.

    Requiere la variable de entorno GEMINI_API_KEY.
    Si no está configurada, el endpoint sigue funcionando con el RAG puro (llm_usado=false).
    """
    materia = req.materia.lower()
    if materia not in MATERIAS:
        raise HTTPException(
            404, f"Materia '{materia}' no encontrada. Disponibles: {sorted(MATERIAS)}"
        )

    # Normalizar grado a 3, 4 o 5 (este endpoint es para primaria media-alta)
    grado = req.grado if req.grado in (3, 4, 5) else 3

    # ── 1. Recuperar contexto ─────────────────────────────────────────────────
    # FAISS semántico si está disponible; JSON keyword search como fallback ligero.
    contexto = _buscar_contexto_faiss(req.pregunta, materia, grado, top_k=5)
    if not contexto:
        contexto = _buscar_contexto_json(req.pregunta, materia, grado, top_k=5)
    tema = contexto[0].get("tema", "") if contexto else ""

    # ── 2. Generar respuesta con Gemini ───────────────────────────────────────
    llm_usado = False
    texto     = ""

    if _gemini_client is not None and contexto:
        try:
            prompt   = _construir_prompt(req.pregunta, materia, grado, contexto)
            response = await _gemini_client.aio.models.generate_content(
                model=_GEMINI_MODEL_NAME,
                contents=prompt,
                config=_genai_types.GenerateContentConfig(
                    max_output_tokens=350,
                    temperature=0.4,
                ),
            )
            # response.text puede lanzar ValueError si el contenido fue bloqueado
            texto = (response.text or "").strip()
            if texto:
                llm_usado = True
        except Exception as exc:
            print(f"[Gemini] Error en /api/preguntar: {exc}")
            texto = ""

    # ── 3. Fallback RAG puro (si Gemini no disponible o falló) ────────────────
    if not texto and contexto:
        texto = contexto[0].get("respuesta", "")

    return {
        "pregunta":   req.pregunta,
        "materia":    materia,
        "grado":      grado,
        "texto":      texto,
        "tema":       tema,
        "encontrado": bool(texto),
        "llm_usado":  llm_usado,
    }

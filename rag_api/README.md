# RAG API — Numi Educativa v3.0

API pública en Python (FastAPI) que sirve las bases de conocimiento offline para el asistente IA de la app Numi.  
Desde v3.0 integra **Google Gemini** (LLM gratuito) para generar respuestas naturales y adaptadas al grado del estudiante.

## Endpoints

| Método | URL | Descripción |
|--------|-----|-------------|
| GET  | `/` | Info general (versión, estado LLM, estado FAISS) |
| GET  | `/api/paquetes` | Lista todos los paquetes disponibles |
| GET  | `/api/paquetes/{materia}/info` | Metadata de un paquete |
| GET  | `/api/paquetes/{materia}` | **Descarga el ZIP** de una materia |
| POST | `/api/buscar_semantico` | Búsqueda semántica FAISS (devuelve entradas crudas) |
| POST | `/api/preguntar` | **Nuevo** — FAISS + Gemini → respuesta natural por grado |

**Materias válidas:** `matematicas`, `ciencias`, `espanol`, `ingles`, `sociales`

---

## Nuevo endpoint `/api/preguntar` (LLM)

### Request

```json
POST /api/preguntar
{
  "pregunta": "¿Qué es la fotosíntesis?",
  "materia":  "ciencias",
  "grado":    4
}
```

### Response

```json
{
  "pregunta":   "¿Qué es la fotosíntesis?",
  "materia":    "ciencias",
  "grado":      4,
  "texto":      "La fotosíntesis es el proceso que usan las plantas para fabricar su propio alimento...",
  "tema":       "fotosíntesis",
  "encontrado": true,
  "llm_usado":  true
}
```

- `llm_usado: true` → respuesta generada por Gemini usando el contexto recuperado.
- `llm_usado: false` → fallback al mejor resultado RAG (si Gemini no está configurado o falla).
- `encontrado: false` → no se encontró contexto relevante (pregunta fuera de la base de conocimiento).

---

## Configurar Google Gemini (gratis)

### 1. Obtener API Key en Google AI Studio

1. Ve a **[aistudio.google.com](https://aistudio.google.com)**
2. Inicia sesión con tu cuenta Google
3. Haz clic en **"Get API key"** → **"Create API key"**
4. Copia la clave generada (formato: `AIzaSy...`)

> El tier gratuito de Gemini 1.5 Flash incluye **1,500 solicitudes/día** y **1,000,000 tokens/minuto** — más que suficiente para esta app educativa.

### 2. Configurar la variable de entorno

**En Railway:**
1. Ve al servicio → pestaña **Variables**
2. Añade: `GEMINI_API_KEY` = `AIzaSy...` (tu clave)
3. El servicio se reiniciará automáticamente

**En Render:**
1. Ve al servicio → **Environment**
2. Añade la variable `GEMINI_API_KEY`

**Localmente:**
```bash
export GEMINI_API_KEY="AIzaSy..."
uvicorn main:app --reload --port 8000
```

**En Windows (CMD):**
```cmd
set GEMINI_API_KEY=AIzaSy...
uvicorn main:app --reload --port 8000
```

### 3. Modelo por defecto

El modelo predeterminado es `gemini-1.5-flash`. Puedes cambiarlo con la variable:

```
GEMINI_MODEL=gemini-1.5-flash    # predeterminado (recomendado, tier free)
GEMINI_MODEL=gemini-2.0-flash    # alternativa más reciente
```

---

## Comportamiento sin API Key (degradado)

Si `GEMINI_API_KEY` no está configurada o el paquete `google-generativeai` no está instalado:

- Los endpoints `/api/paquetes/*` y `/api/buscar_semantico` funcionan con normalidad.
- El endpoint `/api/preguntar` devuelve la respuesta directa del RAG (sin pasar por LLM), con `llm_usado: false`.
- La app Flutter sigue funcionando con su motor BM25 + TFLite local como fallback.

---

## Ejecutar localmente

```bash
cd rag_api
pip install -r requirements.txt
export GEMINI_API_KEY="AIzaSy..."   # opcional
uvicorn main:app --reload --port 8000
```

Abre: http://localhost:8000/docs

---

## Desplegar en Railway (recomendado)

1. Crea cuenta en https://railway.app
2. Nuevo proyecto → "Deploy from GitHub repo"
3. Selecciona este repositorio, carpeta `/rag_api`
4. Railway detecta el Dockerfile automáticamente
5. En Variables, añade `GEMINI_API_KEY` con tu clave de Google AI Studio
6. Copia la URL pública que genera Railway
7. Pégala en Flutter: `flutter_code/lib/data/services/rag_service.dart` → `_apiBase`

---

## Desplegar en Render (alternativa gratuita)

1. Crea cuenta en https://render.com
2. New → Web Service → Connect repo
3. Root Directory: `rag_api`
4. Build Command: `pip install -r requirements.txt`
5. Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. En Environment, añade `GEMINI_API_KEY`
7. Copia la URL y actualiza `_apiBase` en el servicio Flutter

---

## Actualizar el contenido

Edita los archivos JSON en `knowledge_base/` y re-despliega.  
Los ZIPs se regeneran automáticamente y los índices FAISS se reconstruyen al reiniciar.

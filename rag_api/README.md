# RAG API — Numi Educativa

API pública en Python (FastAPI) que sirve las bases de conocimiento offline para el asistente IA de la app Numi.

## Endpoints

| Método | URL | Descripción |
|--------|-----|-------------|
| GET | `/` | Info general de la API |
| GET | `/api/paquetes` | Lista todos los paquetes disponibles |
| GET | `/api/paquetes/{materia}/info` | Metadata de un paquete |
| GET | `/api/paquetes/{materia}` | **Descarga el ZIP** de una materia |

**Materias válidas:** `matematicas`, `ciencias`, `espanol`, `ingles`, `sociales`

---

## Ejecutar localmente

```bash
cd rag_api
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Abre: http://localhost:8000/docs

---

## Desplegar en Railway (gratis)

1. Crea cuenta en https://railway.app
2. Nuevo proyecto → "Deploy from GitHub repo"
3. Selecciona este repositorio, carpeta `/rag_api`
4. Railway detecta el Dockerfile automáticamente
5. Copia la URL pública que genera Railway
6. Pégala en Flutter: `flutter_code/lib/data/services/descarga_paquete_service.dart` línea `_apiBase`

---

## Desplegar en Render (gratis)

1. Crea cuenta en https://render.com
2. New → Web Service → Connect repo
3. Root Directory: `rag_api`
4. Build Command: `pip install -r requirements.txt`
5. Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
6. Copia la URL y actualiza `_apiBase` en el servicio Flutter

---

## Actualizar el contenido

Edita los archivos JSON en `knowledge_base/` y re-despliega. Los ZIPs se regeneran automáticamente al recibir la próxima solicitud de descarga.

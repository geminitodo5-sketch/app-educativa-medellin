---
name: RAG System Implementation
description: Sistema RAG offline para el asistente IA de Numi — arquitectura y decisiones clave
type: project
---

El sistema RAG (Retrieval-Augmented Generation) fue construido el 2026-04-25. Solo disponible para grados 3, 4 y 5 (restricción del usuario).

**Why:** El usuario quiere un asistente IA educativo que funcione 100% offline después de descargar el paquete de cada materia.

**Estructura:**
- Backend: `backend/` (antes `rag_api/`) — Python FastAPI. Servicio de contenido en `backend/app/content/` (público, 5 endpoints, sirve ZIPs). Datos de usuario en `backend/app/users/` con BD propia.
- Knowledge base: `backend/knowledge_base/{materia}.json` — 5 materias, grados 1-5, ~15-25 entradas cada una.
- SQLite: tabla `base_conocimiento` añadida en migración v3 (usa `'espanol'` sin acento, a diferencia de `historial_rag` que usa `'español'` con acento — hay mapeo en `rag_service.dart`).
- Flutter services: `descarga_paquete_service.dart` (descarga ZIP → extrae → importa SQLite), `rag_service.dart` (TF-IDF offline, tokenización con normalización de acentos).
- Flutter UI: `lib/ui/views/asistente_ia/asistente_ia_view.dart` — pantalla de chat con selector de materias y botón de descarga.
- Botón en `menu_1_y_2_view.dart` — icono `psychology_rounded`, solo visible si `nivel >= 3`.

**How to apply:** Para cambiar el URL del backend usar `--dart-define=API_BASE_URL` o `frontend/lib/data/services/api_config.dart`. Para añadir contenido editar los JSON en `backend/knowledge_base/`.

---
name: RAG System Implementation
description: Sistema RAG offline para el asistente IA de Numi — arquitectura y decisiones clave
type: project
---

El sistema RAG (Retrieval-Augmented Generation) fue construido el 2026-04-25. Solo disponible para grados 3, 4 y 5 (restricción del usuario).

**Why:** El usuario quiere un asistente IA educativo que funcione 100% offline después de descargar el paquete de cada materia.

**Estructura:**
- Backend: `rag_api/` — Python FastAPI, público, sin autenticación. 5 endpoints. Sirve ZIPs con JSON de conocimiento.
- Knowledge base: `rag_api/knowledge_base/{materia}.json` — 5 materias, grados 1-5, ~15-25 entradas cada una.
- SQLite: tabla `base_conocimiento` añadida en migración v3 (usa `'espanol'` sin acento, a diferencia de `historial_rag` que usa `'español'` con acento — hay mapeo en `rag_service.dart`).
- Flutter services: `descarga_paquete_service.dart` (descarga ZIP → extrae → importa SQLite), `rag_service.dart` (TF-IDF offline, tokenización con normalización de acentos).
- Flutter UI: `lib/ui/views/asistente_ia/asistente_ia_view.dart` — pantalla de chat con selector de materias y botón de descarga.
- Botón en `menu_1_y_2_view.dart` — icono `psychology_rounded`, solo visible si `nivel >= 3`.

**How to apply:** Para cambiar el URL del backend editar `descarga_paquete_service.dart` constante `_apiBase`. Para añadir contenido editar los JSON en `rag_api/knowledge_base/`.

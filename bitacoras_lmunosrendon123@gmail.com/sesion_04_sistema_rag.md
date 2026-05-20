# Bitácora IA — Sesión 04
## Sistema RAG — Búsqueda Semántica Offline

**Fechas:** 26 al 29 de abril de 2026  
**Commits:** `55e84298` → `3225c477` — *RAG v1→v4, FAISS, TFLite, embeddings, API Railway*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Implementar un sistema de Recuperación Aumentada de Generación (RAG) que permita al asistente de IA responder preguntas educativas sin conexión a internet. El sistema debía buscar información relevante en una base de conocimiento local y generar respuestas adaptadas al grado del estudiante.

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | ¿Qué es RAG y cómo aplicarlo en una app móvil offline? | RAG = Retrieval + Generation. Para offline: embeddings precalculados en SQLite + modelo TFLite en dispositivo |
| 2 | ¿Cómo hacer búsqueda semántica sin internet? | Embeddings de texto en SQLite + similitud coseno calculada en Dart; fallback con BM25 (frecuencia de palabras) |
| 3 | ¿Cómo crear embeddings sin PyTorch en Railway (límite 4 GB)? | Migrar de `sentence-transformers` (~2 GB) a `fastembed` (~500 MB con modelo ONNX) |
| 4 | ¿Cómo evitar que el servidor de Railway falle si no cargan las librerías ML? | `try/except ImportError` con `_ML_AVAILABLE = False`; servidor arranca siempre, ML es opcional |
| 5 | ¿Cómo adaptar las respuestas al nivel del niño? | Función `_interpretarParaNino()` con tres niveles: grado 3 (emojis, muy simple), grado 4 (claro), grado 5 (técnico) |
| 6 | ¿Cómo inicializar FAISS sin bloquear el arranque del servidor? | `asyncio.Task` en `lifespan`: lanza `_init_faiss_background()` sin esperar, el servidor queda disponible de inmediato |

---

## Arquitectura RAG implementada

```
Pregunta del niño
      ↓
EmbeddingService (TFLite offline)
      ↓  [fallback automático si no hay modelo]
Hash-bag + bigramas normalizados
      ↓
RAGRepository → SQLite (vectores precalculados)
      ↓  [búsqueda por similitud coseno]
Top-5 fragmentos relevantes
      ↓
LocalLlmService (Gemma 2B) / respuesta formateada
      ↓
Respuesta adaptada al grado
```

---

## Decisiones técnicas tomadas

- **FAISS** en servidor Railway como búsqueda primaria (timeout 6 s → cae a BM25 offline)
- **TFLite** en dispositivo para embeddings locales; fallback a hash-bag+bigramas cuando no hay modelo `.tflite`
- **`opcionA` siempre es la correcta** en `BancoPreguntasService`; el runtime baraja las posiciones para que no sea predecible
- Banco de 150 preguntas MCQ precargadas en SQLite (10 por grado × materia)
- Respuestas estructuradas: apertura + bullet points + ejemplo + cierre motivador

---

## Código generado con IA

- `EmbeddingService`: TFLite completo con fallback hash-bag+bigramas
- `RAGService` v4.0: FAISS server + TFLite reranking + respuestas interpretadas
- `BancoPreguntasService`: 150 preguntas con baraja aleatoria por sesión
- `DescargaPaqueteService`: descarga ZIPs desde API pública, descomprime e importa a SQLite
- `main.py` API Railway: FAISS init en background, endpoints de descarga de paquetes

---

## Complicaciones encontradas

| Problema | Causa | Solución IA |
|----------|-------|-------------|
| Imagen Docker de 6 GB supera límite Railway | `sentence-transformers` + `faiss-cpu` + `numpy` demasiado grandes | Migrar a `fastembed` (ONNX, ~500 MB); tensor `UnmodifiableUint8ListView` → `Uint8List.fromList` |
| Railway health check fallaba al iniciar | FAISS bloqueaba el lifespan hasta cargar el modelo | `asyncio.Task` para lanzar FAISS en background sin bloquear |
| Matches falsos en búsqueda (ej: "primera guerra" vs "segunda guerra") | BM25 simple no distinguía orden de palabras | Búsqueda por bigramas + palabras exactas para reducir falsos positivos |
| Respuestas copiaban texto literalmente del corpus | `_construirRespuesta()` hacía copy-paste sin interpretar | Reescritura con `_interpretarParaNino()`: formato estructurado y lenguaje adaptado |

---

## Resultado

Sistema RAG v4.0 operativo. Búsqueda semántica offline funcional con TFLite. API en Railway como respaldo. Respuestas adaptadas a 3 niveles de grado. 150 preguntas MCQ precargadas en SQLite.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*

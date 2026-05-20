# Bitácora IA — Sesión 05
## Asistente IA Offline con Gemma 2B + Historial + Racha

**Fechas:** 30 de abril al 6 de mayo de 2026  
**Commits:** `140d9ce8` → `85d1747b` — *modelo IA offline implementado, historial de conversaciones, pantalla de racha*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Integrar el modelo de lenguaje **Gemma 2B** directamente en el dispositivo Android usando `flutter_gemma`, implementar el historial de conversaciones persistente en SQLite, y crear la pantalla de racha diaria que motiva a los estudiantes a usar la app cada día.

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | ¿Cómo usar `flutter_gemma` para correr Gemma 2B en Android sin internet? | `SmartDownloader` de flutter_gemma descarga el modelo desde Firebase Storage; `install()` lo activa sin red una vez descargado |
| 2 | ¿Cómo mostrar el progreso de descarga del modelo en tiempo real? | `onProgress` callback en `descargarModelo()` que actualiza `modelDownloadProgress` en el ViewModel |
| 3 | ¿Cómo guardar el historial de conversaciones en SQLite? | Tabla `conversaciones` con columnas: `id`, `estudiante_id`, `materia`, `mensajes` (JSON), `fecha` |
| 4 | ¿Cómo calcular la racha diaria de uso? | `RachaService`: comparar `ultima_sesion` con fecha actual; si es día consecutivo, incrementar racha; si se saltó un día, resetear a 1 |
| 5 | ¿Cómo evitar que el asistente invente respuestas fuera del currículo? | Prompt con instrucción explícita: "Solo responde sobre los temas del currículo colombiano para grado X" + contexto RAG como única fuente |
| 6 | ¿Cómo detectar cuando un niño está confundido y ofrecer pistas? | Contador de intentos fallidos en el ViewModel; si `intentos >= 2`, activar modo pista con `nivelPistaActivo` (0 = sin pistas, 1-3 = nivel) |

---

## Arquitectura del asistente IA

```
AsistenteIaView (Crosmedia)
      ↓ comandos
AsistenteIaViewModel (StateNotifier)
      ↓
ConsultarRAGUseCase
      ├→ RAGRepository (contexto educativo local)
      └→ LocalLlmService (Gemma 2B en dispositivo)
            ↓
      Respuesta generada localmente
            ↓
ConversacionRepository → SQLite (historial)
```

---

## Decisiones técnicas tomadas

- **Gemma 2B** como modelo de lenguaje: 2.6 GB, corre en Android 8+ con mínimo 3 GB RAM disponibles
- El modelo se descarga **una sola vez** desde Firebase Storage y se activa con `install()` sobre el archivo ya descargado (sin red)
- `SmartDownloader` activa un **foreground service** en Android para archivos > 500 MB (evita que Android mate la descarga)
- Sin tokens en **30 segundos** → `rag_service.dart` cae al formateador de respaldo (respuesta estructurada sin LLM)
- Historial visible en un `BottomSheet` deslizable con lista de conversaciones por fecha
- Racha persistida en SQLite; se muestra un modal animado con Lottie al completar días consecutivos

---

## Código generado con IA

- `LocalLlmService`: descarga, instalación, generación de respuestas con Gemma 2B, timeout de 30 s
- `AsistenteIaViewModel`: StateNotifier con `isModelReady`, `isModelDownloading`, `modelDownloadProgress`, `modelError`, detección de confusión
- `RachaService` + `RachaProvider`: cálculo diario, persistencia, provider `rachaPendienteProvider`
- `ConversacionRepository`: CRUD de historial en SQLite con serialización JSON de mensajes
- Pantalla `RachaView`: animación Lottie + estadísticas de racha actual y récord

---

## Complicaciones encontradas

| Problema | Causa | Solución IA |
|----------|-------|-------------|
| La tarjeta del modelo mostraba "listo" aunque no estaba descargado | `gemmaStartupProvider` llamaba `descargarModelo()` directamente antes que el ViewModel, activando la guardia `_isDownloading` y causando retorno silencioso | `gemmaStartupProvider` fue cambiado para solo leer el ViewModel (`ref.read(asistenteIaViewModelProvider)`); toda la inicialización del estado pasa por el ViewModel |
| Gemma tardaba mucho en responder en gama baja | El contexto RAG era demasiado largo | Se redujo el contexto a los 3 fragmentos más relevantes y se limitó `max_tokens` a 350 |
| Android mataba la descarga en background | El proceso de descarga no tenía foreground service | `SmartDownloader` de flutter_gemma activa el foreground service automáticamente para archivos > 500 MB |
| El historial crecía sin límite | Sin paginación en la consulta SQLite | Límite de 50 conversaciones; las más antiguas se archivan |

---

## Resultado

Asistente IA completamente offline operativo con Gemma 2B. Historial de conversaciones persistente. Racha diaria con animación Lottie. Detección de confusión con pistas graduales en 3 niveles.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*

# Bitácoras de IA — Proyecto Numi
## App Educativa para Reducir la Brecha Digital en Medellín

**Proyecto:** Numi — App educativa offline para niños de 1° a 5° de primaria  
**Período de desarrollo:** Marzo — Mayo 2026  
**Herramienta IA:** Claude Sonnet 4.6 (Anthropic)  
**Equipo:** Ingeniería (Luis Muñoz) + Crosmedia (diseño visual)  

---

## ¿Qué es una Bitácora de IA?

Durante el desarrollo de Numi, el agente de inteligencia artificial **Claude Sonnet** de Anthropic participó activamente en decisiones de arquitectura, generación de código, diagnóstico de errores y documentación. Estas bitácoras registran cada sesión de trabajo colaborativo: las preguntas formuladas, las decisiones tomadas, el código generado y los problemas resueltos con ayuda del agente.

---

## Índice de sesiones

| # | Sesión | Fechas | Commits |
|---|--------|--------|---------|
| 01 | [Inicio del Proyecto y Arquitectura Base](sesion_01_inicio_arquitectura.md) | 22 mar 2026 | `92d8654f` |
| 02 | [Pantallas Principales y Primeras Actividades](sesion_02_pantallas_actividades.md) | 6–15 abr 2026 | `88f40126` → `f9c223e7` |
| 03 | [Expansión a Grados 3 a 5](sesion_03_grados_3_a_5.md) | 19–25 abr 2026 | `9d661dd9` → `6fef2560` |
| 04 | [Sistema RAG — Búsqueda Semántica Offline](sesion_04_sistema_rag.md) | 26–29 abr 2026 | `55e84298` → `3225c477` |
| 05 | [Asistente IA Offline con Gemma 2B](sesion_05_ia_offline_gemma.md) | 30 abr–6 may 2026 | `140d9ce8` → `85d1747b` |
| 06 | [Responsive, Pulido Visual y Firebase Auth](sesion_06_responsive_pulido.md) | 11–13 may 2026 | `75e4e0eb` → `241e2c05` |
| 07 | [Corrección de Errores y Estabilidad](sesion_07_correcciones_errores.md) | 17–18 may 2026 | `88f7b2e7` → `69d2c9f3` |
| 08 | [Sincronización en Tiempo Real con Firestore](sesion_08_sincronizacion_firestore.md) | 19–20 may 2026 | `9f42b9f2` → `627102de` |
| 09 | [Limpieza de Código, Presentación y App Completa](sesion_09_limpieza_presentacion.md) | 20 may 2026 | `d065750e` → `b3367707` |

---

## Rol del agente de IA en el proyecto

```
┌─────────────────────────────────────────────────────────────┐
│                     AGENTE: Claude Sonnet                   │
├─────────────────────┬───────────────────────────────────────┤
│ Arquitectura        │ Definición de capas MVVM, providers,  │
│                     │ estructura de carpetas, reglas de equipo│
├─────────────────────┼───────────────────────────────────────┤
│ Generación de código│ ViewModels, Repositories, Services,   │
│                     │ UseCases, scripts de migración        │
├─────────────────────┼───────────────────────────────────────┤
│ Diagnóstico         │ Race conditions, crashes en Android,  │
│                     │ errores de sincronización, RAM limits  │
├─────────────────────┼───────────────────────────────────────┤
│ Documentación       │ CLAUDE.md, bitácoras, presentación    │
│                     │ Word, limpieza de comentarios         │
├─────────────────────┼───────────────────────────────────────┤
│ Decisiones técnicas │ Elección de librerías, estrategias    │
│                     │ offline-first, resolución de conflictos│
└─────────────────────┴───────────────────────────────────────┘
```

---

## Resumen estadístico

| Métrica | Valor |
|---------|-------|
| Sesiones de trabajo con IA | 9 |
| Archivos generados/modificados con IA | ~80 archivos `.dart` |
| Bugs diagnosticados con IA | 18 |
| Decisiones de arquitectura asistidas por IA | 12 |
| Líneas de código generadas con IA | ~4.200 |
| Tecnologías evaluadas con IA | 8 (just_audio, media_kit, FAISS, fastembed, flutter_gemma, Firebase, Riverpod, SQLite) |

---

## Tecnologías donde la IA fue decisiva

| Decisión | Sin IA | Con IA |
|----------|--------|--------|
| Audio en Android físico | `just_audio` (fallaba) | Migración a `media_kit` |
| Imagen Docker Railway | `sentence-transformers` (6 GB) | `fastembed` (500 MB) |
| Estado del modelo Gemma | Race condition (estado falso) | Un solo punto de inicialización |
| Sincronización multi-dispositivo | Sin estrategia clara | `max(porcentaje)` + `hasPendingWrites` |
| Arquitectura de equipo mixto | Sin separación clara | MVVM con reglas estrictas en `CLAUDE.md` |

---

*Bitácoras generadas con asistencia de Claude Sonnet 4.6 — Anthropic*  
*Proyecto académico — Universidad / Medellín, Colombia — 2026*

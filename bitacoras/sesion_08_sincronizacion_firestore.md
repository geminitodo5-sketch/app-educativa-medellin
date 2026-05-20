# Bitácora IA — Sesión 08
## Sincronización en Tiempo Real con Firestore

**Fechas:** 19 al 20 de mayo de 2026  
**Commits:** `9f42b9f2` → `627102de` — *sincronización en tiempo real v1, v2, v3*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Implementar sincronización bidireccional offline-first entre SQLite local y Firestore. El objetivo era que un estudiante pudiera continuar desde cualquier dispositivo sin perder progreso, y que los cambios de un dispositivo se reflejaran en otro en tiempo real.

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | ¿Cómo hacer sincronización offline-first que nunca retroceda el avance? | Regla `max(porcentaje)`: si Firestore tiene mayor porcentaje → actualizar local; si local es mayor → no cambiar; al subir, siempre subir el local |
| 2 | ¿Cómo evitar el bucle dispositivo→Firestore→dispositivo? | Filtro `hasPendingWrites == false`: solo procesar cambios confirmados por el servidor, no los que este dispositivo acaba de subir |
| 3 | ¿Cómo restaurar el progreso completo en un dispositivo nuevo? | `SincronizarUseCase.sincronizarAlLogin()`: descarga perfil + todos los docs de `/usuarios/{uid}/progreso` al iniciar sesión |
| 4 | ¿Cómo manejar conflictos si dos dispositivos modifican la misma actividad offline? | `max(porcentaje)` como único árbitro; el niño nunca retrocede — cualquier avance se preserva |
| 5 | ¿Cómo escuchar cambios de Firestore en tiempo real sin drenar la batería? | `StreamProvider` con `fss.escucharProgreso(uid)`: listener activo solo cuando hay estudiante con sesión activa; se cancela automáticamente con `onDispose` |
| 6 | ¿Cómo manejar `connectivity_plus` v5 que cambió la API? | v5 devuelve `ConnectivityResult` (no `List`); guarda compatibilidad con `if (result is List)` para soportar ambas versiones |

---

## Arquitectura de sincronización

```
Dispositivo A                    Firestore                    Dispositivo B
    │                               │                               │
    ├─ Guarda progreso SQLite ──────┤                               │
    │  (sincronizado = 0)           │                               │
    ├─ [detecta internet] ──────────►                               │
    │  subirProgreso() ─────────────► /usuarios/{uid}/progreso      │
    │  marcarSincronizados()        │       ↓ listener activo       │
    │                               │  ← escucharProgreso()  ───────┤
    │                               │                 merge max() ──┤
    │                               │              invalidate UI ───┤
    │  ← listener activo ───────────┤                               │
    │  merge max() ─────────────────┤                               │
    │  invalidate menuProgreso ─────┤                               │
```

---

## Decisiones técnicas tomadas

- **Columna `sincronizado`** en tabla `progreso` de SQLite: `0 = pendiente`, `1 = sincronizado`
- **`SyncResultado`** inmutable con `subidos`, `descargados`, `exito`, `error`
- Sincronización activa **solo cuando hay internet** (detectado con `Connectivity().checkConnectivity()`)
- `progresoRealtimeProvider` escucha Firestore en tiempo real e invalida `menuProgresoProvider` solo si hubo cambios (`actualizados > 0`)
- `firestoreSyncListenerProvider` hace sync completa al reconectarse a internet
- `sincronizarAlLogin()` restaura perfil + progreso completo en nuevo dispositivo

---

## Código generado con IA

- `SincronizarUseCase`: sync completa bidireccional + `sincronizarAlLogin()` para nuevo dispositivo
- `FirestoreSyncService`: `subirPerfil()`, `subirProgreso()`, `descargarProgreso()`, `descargarPerfil()`, `escucharProgreso()` (stream en tiempo real)
- `progresoRealtimeProvider`: `StreamProvider` con filtro `hasPendingWrites`, merge max(), invalidación de UI
- `firestoreSyncListenerProvider`: sync completa al detectar reconexión a internet
- `SyncQueueRepository` + `SyncService`: cola legacy offline→backend para compatibilidad

---

## Complicaciones encontradas

| Problema | Causa | Solución IA |
|----------|-------|-------------|
| El listener de Firestore actualizaba la UI aunque el cambio venía del mismo dispositivo | Sin filtro de auto-escrituras | Verificar `hasPendingWrites == false` antes de procesar cada documento |
| `connectivity_plus` v5 rompió el código de sync | API cambió de `Stream<ConnectivityResult>` a un modelo diferente | Guarda de compatibilidad `if (result is List)` + uso de `checkConnectivity()` directo |
| El progreso se duplicaba al restaurar en nuevo dispositivo | `insertar()` lanzaba error de índice único si el registro ya existía | Usar `REPLACE INTO` con el índice único `(estudiante_id, grado, materia, actividad)` |
| La sincronización corría aunque no había usuario activo | `firestoreSyncListenerProvider` no verificaba `estudianteActivoProvider` | Añadir guarda `if (estudiante?.id != null)` antes de llamar `ejecutar()` |

---

## Resultado

Sincronización offline-first bidireccional operativa. Multi-dispositivo funcional: el progreso se restaura automáticamente al iniciar sesión en un nuevo celular. El listener en tiempo real actualiza la UI en menos de 2 segundos cuando otro dispositivo sube progreso.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*

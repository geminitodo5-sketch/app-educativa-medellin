# Bitácora IA — Sesión 07
## Corrección de Errores y Estabilidad

**Fechas:** 17 al 18 de mayo de 2026  
**Commits:** `88f7b2e7` → `69d2c9f3` — *modificaciones y arreglos de errores v1, v2, v3*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Identificar y corregir errores detectados durante pruebas en dispositivos físicos Android. La mayoría de los fallos eran de tipo runtime (no compilación), por lo que se requirió análisis de trazas de error y prueba en hardware real.

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | El audio no reproduce en Android físico con `just_audio` | Migrar a `media_kit` + `media_kit_video`; usa `Media('asset:///assets/audio/xxx.mp3')` nativo |
| 2 | ¿Cómo reproducir audio y video simultáneamente en el modal de felicitaciones? | `media_kit` maneja múltiples instancias de `Player` independientes; crear un `Player` para audio y otro para video |
| 3 | Los audios se traslapan cuando el usuario navega rápido | Llamar `await _player?.stop()` antes de `await _player?.open()` cada vez que se inicia un nuevo audio |
| 4 | `NullPointerException` al acceder al progreso antes de cargar el estudiante | Añadir guarda `if (estudiante == null || estudiante.id == null) return {};` en `menuProgresoProvider` |
| 5 | La app se congela al inicializar Gemma en dispositivos con 2 GB RAM | Inicializar Gemma en un `Isolate` separado; no bloquear el hilo principal de Flutter |
| 6 | Los porcentajes del menú no se actualizan al terminar una actividad | Llamar `ref.invalidate(menuProgresoProvider)` desde el ViewModel al guardar progreso |

---

## Errores corregidos

### Error 1 — Audio no reproduce en Android físico
- **Síntoma:** Silencio total al entrar a actividades con audio en dispositivo físico; en emulador funcionaba
- **Causa:** `just_audio` no resolvía correctamente los paths de assets en Android release
- **Solución:** Migración completa a `media_kit`; el path `asset:///assets/audio/xxx.mp3` es resuelto nativamente por media_kit sin depender del `AssetBundle`

### Error 2 — Traslape de audios entre actividades
- **Síntoma:** Al navegar entre tarjetas rápido, varios audios sonaban al mismo tiempo
- **Causa:** Cada tarjeta creaba su propio `Player` sin detener el anterior
- **Solución:** Un único `Player?` por pantalla; `await _player?.stop()` antes de reproducir nuevo audio

### Error 3 — Porcentajes del menú no actualizan
- **Síntoma:** Completar una actividad no actualizaba la barra de progreso del menú hasta reiniciar la app
- **Causa:** `menuProgresoProvider` es un `FutureProvider`; no se invalida automáticamente al guardar progreso
- **Solución:** `ref.invalidate(menuProgresoProvider)` en cada ViewModel que guarde progreso

### Error 4 — Crash al volver al menú desde Gemma en RAM baja
- **Síntoma:** La app se cerraba al presionar "atrás" desde el asistente en dispositivos con 2 GB RAM
- **Causa:** `LocalLlmService` no liberaba el modelo al salir de la pantalla
- **Solución:** `ref.onDispose` en el provider del servicio llama a `cerrar()` que libera la memoria del modelo

### Error 5 — Texto "¡Casi lo tienes!" confundía a los niños
- **Síntoma:** Los niños entendían que estaban casi correctos cuando en realidad fallaron
- **Causa:** El mensaje era ambiguo para niños de 6-8 años
- **Solución:** Cambiado a "¡Inténtalo de nuevo!" en las 29 actividades afectadas

---

## Código modificado con IA

- Migración de `just_audio` a `media_kit` en 6 archivos de vista
- `LocalLlmService.cerrar()` + `ref.onDispose` en `musicaServiceProvider`
- `menuProgresoProvider` invalidado correctamente desde 5 ViewModels
- Guardas nulas en `progresoRealtimeProvider` y `firestoreSyncListenerProvider`

---

## Resultado

App estable en dispositivos físicos Android 8+ con 2 GB RAM. Audio funcionando correctamente. Progreso del menú actualizándose en tiempo real. Sin crashes conocidos en el flujo principal.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*

# Bitácora IA — Sesión 02
## Pantallas Principales y Primeras Actividades

**Fechas:** 6 al 15 de abril de 2026  
**Commits:** `88f40126` → `f9c223e7` — *bienvenida, menú, matemáticas, base de datos, etapa 1 completa*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Construir las pantallas de navegación base (bienvenida, selección de grado, menú principal) e implementar las primeras actividades educativas de la etapa 1. También integrar SQLite para persistencia del progreso de los estudiantes.

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | ¿Cómo hacer una pantalla de bienvenida con selección de avatar (pollito/mono)? | Widget `_AvatarOpcion` con índice de estado `0=ninguno, 1=pollito, 2=monito` |
| 2 | ¿Cómo integrar SQLite y crear la tabla de progreso? | `SqliteService` con método `_crearTablas()`, tabla `progreso` con índice único por (estudiante, grado, materia, actividad) |
| 3 | ¿Cómo calcular el porcentaje de una materia desde múltiples actividades? | `ProgresoRepository.porcentajeMateria()` dividiendo actividades completadas / total |
| 4 | ¿Cómo reproducir audio en actividades offline? | Paquete `just_audio` con assets locales empaquetados en el APK |
| 5 | ¿Cómo implementar drag & drop para actividades infantiles? | `Draggable` y `DragTarget` de Flutter con feedback visual de color |

---

## Decisiones técnicas tomadas

- Tipografía **Poppins** integrada como asset local (sin CDN)
- Audio de actividades empaquetado directamente en `assets/audio/` (no streaming)
- Progreso calculado como porcentaje: `(actividades_completadas / total) * 100`
- Pantalla de bienvenida guarda el estudiante activo en `estudianteActivoProvider` (StateProvider global)
- Menú principal con barra de progreso por materia leyendo de SQLite

---

## Actividades implementadas en esta etapa

**Matemáticas (Grado 1-2):**
- Los Números — reconocimiento de cifras con drag & drop
- ¿Quién Tiene Más? — comparación de cantidades
- Sumar — suma visual con animaciones

**Ciencias Naturales:**
- ¿Vivo o No Vivo? — clasificación de seres con tarjetas
- Cuerpo Humano — identificación de partes del cuerpo
- Los Animales — clasificación por hábitat
- Las Plantas — partes de la planta

---

## Código generado con IA

- `SqliteService` completo con métodos `insertar`, `consultar`, `actualizar`, `eliminar`
- `ProgresoRepository` con cálculo de porcentaje por materia
- `EstudianteRepository` con operaciones CRUD + `obtenerOCrearPorDefecto()`
- Flujo de navegación: Bienvenida → Selección de Grado → Menú
- Modal de felicitaciones (`FelicitacionesModal`) con video y audio simultáneos

---

## Complicaciones encontradas

| Problema | Solución IA |
|----------|-------------|
| El audio no reproducía en Android físico | Se verificó que el path del asset usara el formato correcto `assets/audio/xxx.mp3` |
| Pantalla blanca al iniciar la app | Se ocultaron líneas de `main.dart` que iniciaban pantallas de prueba antes de la bienvenida |
| Drag & drop no respondía en pantallas pequeñas | Se ajustaron los `hitTestBehavior` y se aumentó el área de tap con `padding` |

---

## Resultado

Etapa 1 completada: pantallas base funcionales, 7 actividades educativas operativas, progreso guardado en SQLite, audio offline funcionando.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*

# Bitácora IA — Sesión 01
## Inicio del Proyecto y Arquitectura Base

**Fecha:** 22 de marzo de 2026  
**Commit inicial:** `92d8654f` — *estructura del proyecto, app para niños de 1° a 5°, MVVM lista*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Definir la arquitectura del proyecto desde cero para una aplicación educativa offline-first dirigida a niños de 6 a 10 años en zonas rurales de Medellín. El reto principal era elegir un patrón de diseño que permitiera separar las responsabilidades entre el equipo de Ingeniería (lógica) y el equipo de Crosmedia (diseño visual).

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | ¿Qué arquitectura usar para una app Flutter con múltiples pantallas y lógica compleja? | Se recomendó MVVM con Riverpod, siguiendo la guía oficial de Flutter |
| 2 | ¿Cómo separar responsabilidades entre diseño y lógica en un equipo mixto? | Regla estricta: Views solo manejan lógica visual, ViewModels gestionan estado y comandos |
| 3 | ¿Qué base de datos usar para modo offline en gama baja? | SQLite con `sqflite` por su bajo consumo de RAM y funcionamiento sin internet |
| 4 | ¿Cómo estructurar las carpetas del proyecto? | Layer-first: `lib/ui/`, `lib/data/`, `lib/domain/` con rutas exactas por clase |

---

## Decisiones técnicas tomadas

- **Patrón MVVM** con `flutter_riverpod ^2.4.0` como gestor de estado
- **SQLite** (`sqflite`) como base de datos local única fuente de verdad
- **Offline-first**: el dispositivo es la fuente de verdad; el servidor recibe datos en batch
- **Separación de equipos**: Ingeniería no diseña UI, Crosmedia no toca lógica ni datos
- Archivo `CLAUDE.md` creado en la raíz del proyecto como guía permanente para el agente de IA

---

## Código generado con IA

```
lib/
├── ui/
│   ├── views/          ← Crosmedia
│   └── viewmodels/     ← Ingeniería
├── data/
│   ├── repositories/   ← Ingeniería
│   └── services/       ← Ingeniería
└── domain/
    ├── usecases/
    └── models/
```

- Estructura inicial de `pubspec.yaml` con dependencias acordadas
- Modelo base `EstudianteModel` con campos: `id`, `nombre`, `grado`, `personaje`, `fechaRegistro`
- Esquema SQLite inicial con tabla `estudiantes`

---

## Complicaciones encontradas

| Problema | Solución IA |
|----------|-------------|
| El equipo no conocía Riverpod | Se creó una guía interna en `CLAUDE.md` con ejemplos del proyecto |
| Duda sobre si usar `Provider` o `StateNotifier` | Se estableció: `StateNotifier` para estado mutable complejo, `Provider` para servicios sin estado |

---

## Resultado

Proyecto inicializado con arquitectura MVVM lista, separación de capas definida y agente de IA configurado con el contexto completo del producto.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*

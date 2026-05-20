# Bitácora IA — Sesión 03
## Expansión a Grados 3 a 5 y Nuevas Pantallas

**Fechas:** 19 al 25 de abril de 2026  
**Commits:** `9d661dd9` → `6fef2560` — *reajuste de pantallas, nuevas pantallas 3° a 5°*  
**Herramienta IA:** Claude Sonnet (Anthropic)  
**Responsable:** Luis Muñoz  

---

## Objetivo de la sesión

Extender la aplicación a los grados 3°, 4° y 5° de primaria. Crear las pantallas de menú diferenciadas (`Menu3A5View`) e implementar nuevas actividades para las 5 áreas de aprendizaje con mayor complejidad cognitiva.

---

## Consultas realizadas al agente de IA

| # | Consulta | Respuesta clave |
|---|----------|-----------------|
| 1 | ¿Cómo manejar dos menús distintos (1°-2° y 3°-5°) sin duplicar código? | Dos views separadas `Menu1Y2View` y `Menu3A5View` con lógica compartida en el ViewModel |
| 2 | ¿Cómo hacer responsive una pantalla para tablets y celulares de gama baja? | `LayoutBuilder` + `MediaQuery` para ajustar tamaños según `constraints.maxWidth` |
| 3 | ¿Cómo implementar actividades de inglés (tarjetas, parejas, escucha)? | Tres ViewModels distintos con estados independientes por tipo de actividad |
| 4 | ¿Cómo crear el juego Detective de Objetos para Sociales? | `GridView` con celdas interactivas, `GlobalKey` para posicionamiento de popups, lógica de "fallo" con color rojo temporal |
| 5 | ¿Cómo implementar "Arma la Palabra" para Español? | `ReorderableListView` con letras individuales como chips arrastrables |

---

## Decisiones técnicas tomadas

- Navegación por grado se determina al hacer login: grados 1-2 van a `Menu1Y2View`, grados 3-5 a `Menu3A5View`
- Todas las actividades guardan progreso con el mismo esquema SQLite (materia + actividad + grado)
- Los assets de audio e imagen se organizan por materia: `assets/images/actividades/{materia}/`
- Menú de inglés con tres módulos por grado (módulo 1, 2, 3)

---

## Actividades implementadas en esta etapa

**Sociales (Grados 3-5):**
- Héroes de la Ciudad — preguntas sobre ciudadanos importantes
- Detective de Objetos — encontrar objetos en escenas de Medellín
- Pasado y Presente — comparar fotos históricas vs actuales

**Español (Grados 3-5):**
- Palabra Loca — completar palabras con letras faltantes
- Arma la Palabra — ordenar sílabas/letras
- Oraciones — construir oraciones con palabras mezcladas

**Inglés (Grados 3-5):**
- Tarjetas de Vocabulario — flashcards con imagen y pronunciación
- Parejas — memory match de palabra-imagen
- Escucha y Elige — audio + opción múltiple

---

## Código generado con IA

- `SocialesViewModel` con `StateNotifier` y carga de progreso desde `ProgresoRepository`
- `InglesViewModel` con lógica de tres módulos y progreso independiente por módulo
- `EspanolViewModel` con manejo de estado para actividades de construcción textual
- `DetectiveObjetosScreen` con `GridView` dinámico y feedback visual inmediato
- Pantallas responsive con `LayoutBuilder` en 18 archivos de vista

---

## Complicaciones encontradas

| Problema | Solución IA |
|----------|-------------|
| El `GridView` del Detective no alineaba los popups correctamente | Se usaron `GlobalKey` por celda para calcular la posición exacta con `findRenderObject()` |
| Las tarjetas de inglés parpadeaban al cambiar | Se envolvieron en `AnimatedSwitcher` con `FadeTransition` |
| El responsive rompía en tablets de 10" | Se añadió un breakpoint en 600px para cambiar de 2 a 3 columnas en la grilla |

---

## Resultado

App extendida a los 5 grados. 15 actividades en total distribuidas en las 5 áreas de aprendizaje. Menús diferenciados por etapa funcionando con navegación fluida.

---

*Generado con asistencia de Claude Sonnet 4.6 — Anthropic*

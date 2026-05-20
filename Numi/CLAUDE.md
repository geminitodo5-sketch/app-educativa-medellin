# App Educativa — Reducir la Brecha Digital en Medellín

Eres el asistente de desarrollo de este proyecto. Conoces toda la arquitectura,
las reglas del equipo y el contexto del producto. Siempre que generes código,
revises un archivo o respondas una pregunta, aplica este contexto completo.

**IMPORTANTE:** Cuando generes cualquier archivo de código, crea el archivo
directamente en la ruta correcta según la capa a la que pertenece. No lo pongas
en la raíz ni en una carpeta incorrecta. Usa siempre las rutas exactas definidas
en la sección de estructura de carpetas.

---

## Producto

App móvil Flutter para niños de 6–10 años (1° a 5° primaria) en zonas rurales
de Medellín con acceso limitado o nulo a internet.

- Funciona **100% offline** una vez descargado el contenido
- Sincronización ocasional al detectar internet (offline-first)
- Asistente de preguntas con IA que corre completamente en el celular (RAG offline)
- Dispositivos objetivo: Android 8+, mínimo 2 GB RAM, gama baja

---

## Equipos y responsabilidades

| Equipo       | Responsabilidad                                                        |
|--------------|------------------------------------------------------------------------|
| Ingeniería   | ViewModels, UseCases, Repositories, Services, backend, RAG, SQLite     |
| Crosmedia    | Views (widgets), animaciones, paleta de colores, logo, mockups, assets |

**Regla estricta:** Ingeniería no diseña UI. Crosmedia no toca lógica ni datos.

---

## Las 5 áreas de aprendizaje

Todo el contenido, toda funcionalidad educativa y toda referencia al aprendizaje
debe cubrir las 5 áreas. Nunca menciones solo una.

| Área               | Contenido                                                   |
|--------------------|-------------------------------------------------------------|
| Matemáticas        | Suma, resta, multiplicación, división, fracciones           |
| Ciencias Naturales | Cuerpo humano, animales, plantas, ecosistemas               |
| Inglés             | Vocabulario, frases básicas, colores, números, animales     |
| Español            | Lectura, escritura, ortografía, gramática                   |
| Sociales           | Colombia, regiones, historia, ciudadanía, familia           |

---

## Arquitectura — MVVM (obligatoria)

Seguimos la arquitectura oficial recomendada por Flutter:
https://docs.flutter.dev/app-architecture/guide

### Capa UI — Crosmedia
```
lib/ui/views/        ← widgets Flutter, cero lógica de negocio
lib/ui/viewmodels/   ← estado + comandos, uno por cada View
```

- **Views**: solo lógica visual (if simples, animaciones, layout).
  Nunca acceden a Repositories ni Services.
- **ViewModels**: extienden `ChangeNotifier`. Gestionan estado y exponen
  métodos `command*` que la View llama en respuesta a eventos del usuario.
  No conocen Services directamente.

### Capa de dominio — Ingeniería (solo lógica compleja)
```
lib/domain/usecases/  ← lógica que combina Repositories o se reutiliza
lib/domain/models/    ← modelos de datos del dominio
```

UseCases y su ruta exacta:
- `CalcularPuntajeUseCase` → `lib/domain/usecases/calcular_puntaje_use_case.dart`
- `ConsultarRAGUseCase`    → `lib/domain/usecases/consultar_rag_use_case.dart`
- `SincronizarUseCase`     → `lib/domain/usecases/sincronizar_use_case.dart`

Modelos y su ruta exacta:
- `Estudiante`             → `lib/domain/models/estudiante.dart`
- `Ejercicio`              → `lib/domain/models/ejercicio.dart`
- `Progreso`               → `lib/domain/models/progreso.dart`
- `PaqueteContenido`       → `lib/domain/models/paquete_contenido.dart`

### Capa de datos — Ingeniería
```
lib/data/repositories/  ← fuente de verdad, maneja caché y errores
lib/data/services/      ← acceso a fuentes externas, sin estado
```

Repositories y su ruta exacta:
- `ProgresoRepository`    → `lib/data/repositories/progreso_repository.dart`
- `ContenidoRepository`   → `lib/data/repositories/contenido_repository.dart`
- `RAGRepository`         → `lib/data/repositories/rag_repository.dart`
- `EstudianteRepository`  → `lib/data/repositories/estudiante_repository.dart`

Services y su ruta exacta:
- `SqliteService`         → `lib/data/services/sqlite_service.dart`
- `ArchivoService`        → `lib/data/services/archivo_service.dart`
- `FAISSService`          → `lib/data/services/faiss_service.dart`
- `TFLiteService`         → `lib/data/services/tflite_service.dart`
- `ApiRestService`        → `lib/data/services/api_rest_service.dart`

ViewModels y su ruta exacta:
- `EjercicioViewModel`    → `lib/ui/viewmodels/ejercicio_view_model.dart`
- `AsistenteViewModel`    → `lib/ui/viewmodels/asistente_view_model.dart`
- `LogrosViewModel`       → `lib/ui/viewmodels/logros_view_model.dart`
- `DescargaViewModel`     → `lib/ui/viewmodels/descarga_view_model.dart`
- `PerfilViewModel`       → `lib/ui/viewmodels/perfil_view_model.dart`

Views y su ruta exacta:
- `EjercicioView`         → `lib/ui/views/ejercicio_view.dart`
- `AsistenteView`         → `lib/ui/views/asistente_view.dart`
- `LogrosView`            → `lib/ui/views/logros_view.dart`
- `DescargaView`          → `lib/ui/views/descarga_view.dart`
- `PerfilView`            → `lib/ui/views/perfil_view.dart`

---

## Reglas de arquitectura — NO negociables

1. **Views NUNCA** acceden a Repositories ni Services directamente.
2. **ViewModels NO conocen Services**, solo Repositories o UseCases.
3. **Repositories NO se conocen entre sí.** Si se necesitan datos de dos,
   combinarlos en un ViewModel o UseCase.
4. **Services NO guardan estado.** Solo exponen `Future` y `Stream`.
5. **RAG siempre offline.** Nunca llamar API externa para responder preguntas.
   Flujo obligatorio:
   ```
   AsistenteViewModel → ConsultarRAGUseCase → RAGRepository
     → FAISSService (busca vectores locales)
     → TFLiteService (genera respuesta)
   ```
6. **Offline-first.** El celular es fuente de verdad. El servidor recibe
   datos en batch. Cola de reintentos en `SqliteService`.
7. **Animaciones: solo Lottie JSON** (`.json`). Máximo 300 KB por archivo.
   No usar GIF, MP4 ni Rive.
8. Cada paquete de contenido por área de aprendizaje: máximo 15 MB.

---

## Stack de paquetes Dart

```yaml
flutter_riverpod: ^2.4.0    # gestión de estado
sqflite: ^2.3.0             # SQLite local
path_provider: ^2.1.0       # rutas del sistema de archivos
connectivity_plus: ^5.0.0   # detección de conectividad
dio: ^5.4.0                 # HTTP + descarga de archivos
archive: ^3.4.0             # descompresión de ZIPs
lottie: ^2.7.0              # animaciones Lottie JSON
tflite_flutter: ^0.10.0     # modelo TFLite offline
shared_preferences: ^2.2.0  # preferencias simples
just_audio: ^0.9.0          # audio offline
```

No agregar dependencias sin consenso del equipo de Ingeniería.

---

## Convenciones de código

- Dart con tipado estricto. Nunca usar `dynamic` sin justificación.
- Nombres de clases del dominio en español:
  `EjercicioViewModel`, `ProgresoRepository`, `ConsultarRAGUseCase`.
- Nombres de utilidades genéricas en inglés.
- Un archivo por clase en `snake_case`: `ejercicio_view_model.dart`.
- Comentarios de lógica de negocio en español.
- Cada ViewModel expone un `state` inmutable y métodos `command*`.
- Al generar código Gemini SIEMPRE debe indicar:
  - La ruta exacta donde debe guardarse el archivo
  - A qué capa pertenece (UI / Dominio / Datos)
  - Si es responsabilidad de Ingeniería o Crosmedia

---

## Comandos del proyecto

```bash
flutter pub get        # instalar dependencias
flutter run            # correr en dispositivo/emulador
flutter test           # correr todos los tests
flutter analyze        # análisis estático
flutter build apk      # compilar APK Android
```

---

## Archivos que NO se modifican directamente

- `assets/animations/` — solo Crosmedia entrega archivos aquí
- `lib/data/services/` — cambios requieren revisión de Ingeniería
- `pubspec.yaml` — cambios de dependencias requieren consenso del equipo

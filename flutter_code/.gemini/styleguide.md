# Guía de estilo — App Educativa Medellín

## Arquitectura

- **Organización Layer-first**: Los archivos se agrupan estrictamente por su capa técnica (UI, Dominio, Datos) en lugar de agruparlos por funcionalidad (Feature-first).
- Todo código debe seguir MVVM: Views → ViewModels → Repositories/UseCases → Services.
- Las Views no pueden importar clases de `lib/data/` ni `lib/domain/`.
- Los ViewModels no pueden importar clases de `lib/data/services/`.
- Los Services no deben tener variables de instancia que guarden estado entre llamadas.
- Los Repositories no deben importarse entre sí.

## Nomenclatura

- Clases de dominio del proyecto en español con sufijo de capa:
  `EjercicioViewModel`, `ProgresoRepository`, `SqliteService`, `SincronizarUseCase`.
- Archivos en `snake_case` que coincidan con el nombre de la clase:
  `ejercicio_view_model.dart`, `progreso_repository.dart`.
- Métodos de ViewModel que respondan a eventos del usuario deben empezar con `command`:
  `commandResponderEjercicio()`, `commandHacerPregunta()`.

## Dart

- Tipado estricto siempre. No usar `dynamic` ni `var` sin tipo inferido claro.
- Preferir `final` sobre `var` donde el valor no cambie.
- Usar `const` en widgets que no dependan de estado.
- Manejar errores con `try/catch` en todos los Services. Nunca dejar excepciones sin capturar.
- Usar `async/await`, no `.then()` en cadena.

## Flutter / UI

- Las Views solo contienen lógica visual: if simples, animaciones, layout.
- Nunca colocar lógica de negocio, cálculos ni acceso a datos dentro de un widget.
- Animaciones exclusivamente con Lottie JSON. No usar GIF ni MP4.
- Cada archivo Lottie JSON debe pesar menos de 300 KB.
- Usar `Consumer` o `ref.watch` de Riverpod para escuchar el ViewModel en la View.

## RAG offline

- El flujo de consulta al asistente IA debe pasar siempre por:
  `AsistenteViewModel → ConsultarRAGUseCase → RAGRepository → FAISSService + TFLiteService`.
- Nunca llamar a una API externa para responder preguntas del niño.
- El modelo TFLite no debe superar 400 MB.

## Contenido educativo

- Toda funcionalidad educativa debe cubrir las 5 áreas de aprendizaje:
  Matemáticas, Ciencias Naturales, Inglés, Español y Sociales.
- El contenido se organiza siempre por área de aprendizaje y grado (1° a 5°).
- Cada paquete de contenido por área no debe superar 15 MB.

## Seguridad

- El PIN del estudiante se guarda siempre como hash SHA-256. Nunca en texto plano.
- No loguear datos personales del estudiante (nombre, grado, progreso) en consola.

## Tests

- Todo UseCase debe tener al menos un test unitario.
- Todo Repository debe tener tests con mocks de sus Services.
- Los ViewModels deben tener tests de estado para cada comando.

## Flujo de Integración para Crosmedia

Cuando el equipo de Crosmedia traiga diseños o assets de editores externos, se seguirá este proceso:

1.  **Gestión de Assets**: Las imágenes deben copiarse a `assets/images/`. Se debe actualizar inmediatamente el `pubspec.yaml` para registrar los nuevos archivos.
2.  **Procesamiento de Código**: Al recibir código de front-end externo, Gemini debe:
    -   Transformarlo en un `ConsumerWidget` de Riverpod.
    -   Separar cualquier lógica de "clics" o "datos" y delegarla a un `ViewModel` (que Ingeniería completará después).
    -   Asegurar que el diseño use los componentes de Material 3 y constantes del proyecto.
3.  **Ubicación**: El archivo resultante debe guardarse estrictamente en `lib/ui/views/`.
4.  **Validación**: Revisar que no se hayan introducido importaciones de capas prohibidas (Domain/Data) en la View.

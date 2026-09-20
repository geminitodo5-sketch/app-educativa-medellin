//  lib/data/services/api_config.dart
//  Capa: Datos — Responsabilidad: Ingeniería
//
//  Única fuente de la URL del backend. Para apuntar a otro servidor sin
//  tocar código:
//    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   (emulador Android)
//    flutter run --dart-define=API_BASE_URL=http://localhost:8000  (Windows/desktop)

class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app-educativa-medellin-production-854b.up.railway.app',
  );
}

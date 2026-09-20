# Numi — App Educativa para Reducir la Brecha Digital en Medellín

App móvil Flutter para niños de 6 a 10 años (1° a 5° de primaria) en zonas rurales de Medellín con acceso limitado o nulo a internet. Funciona **100% offline** una vez instalada y tiene un asistente de IA que corre directamente en el celular, sin necesidad de conexión.

---

## Contenido

- [¿Qué es Numi?](#qué-es-numi)
- [Características principales](#características-principales)
- [Áreas de aprendizaje](#áreas-de-aprendizaje)
- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Asistente IA (RAG + Gemma)](#asistente-ia-rag--gemma)
- [Backend RAG API](#backend-rag-api)
- [Sincronización multi-dispositivo](#sincronización-multi-dispositivo)
- [Equipos](#equipos)

---

## ¿Qué es Numi?

Numi es una herramienta educativa diseñada para niños de comunidades rurales de Medellín que no tienen acceso constante a internet. La app cubre las 5 materias del currículo colombiano de primaria con actividades interactivas, audio, animaciones y un asistente de IA que responde preguntas educativas completamente offline.

**Dispositivos objetivo:** Android 8+, mínimo 2 GB RAM, gama baja  
**Grados:** 1° a 5° de primaria  
**Idioma:** Español (Colombia)

---

## Características principales

| Característica | Descripción |
|----------------|-------------|
| 100% Offline | Funciona sin internet una vez instalada |
| Asistente IA local | Gemma 2B corre directamente en el celular |
| RAG offline | Base de conocimiento en SQLite con búsqueda BM25 + TFLite |
| 15 actividades | Drag & drop, selección múltiple, construir palabras, memory match |
| Progreso persistente | SQLite local con sincronización automática al backend propio |
| Multi-dispositivo | El progreso se restaura al iniciar sesión en otro celular |
| Racha diaria | Sistema de días consecutivos para motivar el uso regular |
| Audio en todas las actividades | Instrucciones y retroalimentación sonora offline |
| Responsive | Funciona en celulares de 5" y tablets de 10" |
| Firebase Auth | Login con email/contraseña o Google Sign-In |

---

## Áreas de aprendizaje

| Área | Actividades | Descripción |
|------|-------------|-------------|
| Matemáticas | Los Números · ¿Quién Tiene Más? · Sumar | Reconocimiento, comparación y suma con elementos visuales |
| Ciencias Naturales | ¿Vivo o No Vivo? · Cuerpo Humano · Los Animales · Las Plantas | Clasificación, identificación y partes del cuerpo/planta |
| Español | Palabra Loca · Arma la Palabra · Oraciones | Completar palabras, ordenar sílabas y construir oraciones |
| Inglés | Tarjetas · Parejas · Escucha y Elige | Vocabulario, memory match y comprensión auditiva |
| Sociales | Héroes de la Ciudad · Detective de Objetos · Pasado y Presente | Ciudadanía, objetos en escenas de Medellín e historia |

---

## Arquitectura

El proyecto sigue la arquitectura **MVVM** recomendada oficialmente por Flutter, con separación estricta entre el equipo de Ingeniería (lógica) y Crosmedia (diseño visual).

```
┌─────────────────────────────────────────────────────────────────┐
│  UI Layer (Crosmedia)                                           │
│  lib/ui/views/          ← Widgets Flutter, cero lógica         │
│  lib/ui/viewmodels/     ← Estado + comandos (StateNotifier)    │
├─────────────────────────────────────────────────────────────────┤
│  Domain Layer (Ingeniería)                                      │
│  lib/domain/usecases/   ← Lógica que combina Repositories      │
│  lib/domain/models/     ← Modelos del dominio                  │
├─────────────────────────────────────────────────────────────────┤
│  Data Layer (Ingeniería)                                        │
│  lib/data/repositories/ ← Fuente de verdad, caché y errores   │
│  lib/data/services/     ← Acceso a fuentes externas, sin estado│
│  lib/data/models/       ← Modelos de datos (SQLite, API)       │
│  lib/data/providers/    ← Providers de Riverpod                │
└─────────────────────────────────────────────────────────────────┘
```

**Reglas no negociables:**
- Views **nunca** acceden a Repositories ni Services directamente
- ViewModels **no conocen** Services, solo Repositories o UseCases
- Services **no guardan estado** — solo exponen `Future` y `Stream`
- RAG **siempre offline** — el celular es la fuente de verdad

---

## Stack tecnológico

### App Flutter

| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.x | Framework UI multiplataforma |
| Dart | 3.x | Lenguaje principal |
| flutter_riverpod | ^2.4.0 | Gestión de estado global |
| sqflite | ^2.3.0 | Base de datos SQLite local |
| firebase_auth | latest | Autenticación email + Google |
| dio | ^5.4 | Cliente HTTP hacia el backend (progreso y contenido) |
| flutter_gemma | ^0.13.6 | LLM Gemma 2B en dispositivo |
| media_kit | latest | Reproducción de audio/video offline |
| connectivity_plus | ^5.0.0 | Detección de conectividad |
| dio | ^5.4.0 | Descarga de paquetes RAG |
| archive | ^3.4.0 | Descompresión de ZIPs |
| just_audio | ^0.9.0 | Audio en actividades |

### Backend RAG API

| Tecnología | Uso |
|------------|-----|
| Python 3.11 | Lenguaje del servidor |
| FastAPI | Framework HTTP |
| FAISS (faiss-cpu) | Búsqueda semántica vectorial |
| fastembed | Embeddings ONNX (reemplaza sentence-transformers) |
| Google Gemini | LLM fallback en la nube |
| Railway.app | Despliegue del servidor |
| Docker | Contenerización |

### Inteligencia Artificial en el dispositivo

```
Pregunta del niño
      ↓
EmbeddingService (TFLite)  ←→  Hash-bag + bigramas (fallback)
      ↓
RAGRepository → SQLite (vectores precalculados)
      ↓  búsqueda BM25 + similitud coseno
Top-3 fragmentos relevantes
      ↓
LocalLlmService → Gemma 2B (corre 100% en el celular)
      ↓
Respuesta adaptada al grado (simple / claro / técnico)
```

---

## Estructura del proyecto

```
app-educativa-medellin/
├── frontend/                      ← App Flutter (solo cliente; datos locales en SQLite)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── ui/
│   │   │   ├── views/             ← Pantallas (Crosmedia)
│   │   │   │   ├── matematicas/
│   │   │   │   ├── ciencias/
│   │   │   │   ├── espanol/
│   │   │   │   ├── inlges/
│   │   │   │   ├── sociales/
│   │   │   │   └── asistente_ia/
│   │   │   └── viewmodels/        ← Estado (Ingeniería)
│   │   ├── data/
│   │   │   ├── models/            ← EstudianteModel, ProgresoModel
│   │   │   ├── repositories/      ← EstudianteRepo, ProgresoRepo, RAGRepo
│   │   │   ├── services/          ← SQLite, Firebase, Gemma, RAG
│   │   │   └── providers/         ← Riverpod providers
│   │   └── domain/
│   │       └── usecases/          ← SincronizarUseCase
│   ├── assets/
│   │   ├── images/actividades/    ← Imágenes por materia
│   │   └── Audio/                 ← Audios de actividades
│   └── android/                   ← Configuración Android nativa
├── backend/                       ← API Python/FastAPI (Railway) — persistencia separada
│   ├── app/
│   │   ├── main.py                ← Ensambla los dos servicios
│   │   ├── content/               ← Servicio de CONTENIDO/IA (público, solo lectura)
│   │   └── users/                 ← Servicio de USUARIOS (perfil + progreso, su propia BD)
│   ├── knowledge_base/            ← JSONs de conocimiento por materia
│   ├── tests/
│   ├── requirements.txt
│   └── Dockerfile
└── bitacoras_lmunosrendon123@gmail.com/   ← Bitácoras de IA
    ├── INDICE.md
    ├── sesion_01_inicio_arquitectura.md
    └── ...
```

---

## Instalación y ejecución

### Requisitos previos

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) con NDK 27.0.12077973
- Android SDK API 34 o superior
- JDK 17 (incluido con Android Studio Hedgehog+)
- Dispositivo Android 8+ o emulador con 2 GB RAM

### Pasos

```bash
# 1. Clonar el repositorio
git clone <url-del-repo>
cd app-educativa-medellin/frontend

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase (requerido para Auth)
# Descarga google-services.json desde Firebase Console
# y colócalo en android/app/google-services.json

# 4. Ejecutar en dispositivo conectado (backend de producción por defecto)
flutter run
#    o contra un backend local:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# 5. Compilar APK de producción
flutter build apk --release
```

### Configurar Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Registra la app Android con el package name `com.example.numi`
3. Habilita **Authentication** (Email/Contraseña + Google)
4. **No** habilites Firestore: los datos de usuario viven en el backend propio
5. Descarga `google-services.json` y colócalo en `android/app/`
6. Agrega el SHA-1 de tu keystore en la configuración de Firebase

> **Sin `google-services.json`:** La app funciona offline (SQLite), pero Auth y la sincronización con el backend no estarán disponibles.

---

## Asistente IA (RAG + Gemma)

El asistente de Numi para grados 3°, 4° y 5° usa un pipeline RAG completamente offline:

1. **Descarga del modelo (primera vez):** El modelo Gemma 2B (~2.6 GB) se descarga automáticamente desde Hugging Face cuando el estudiante accede al asistente por primera vez. Requiere internet solo para esta descarga inicial.

2. **Uso offline:** Una vez descargado, Gemma corre en el dispositivo sin ninguna conexión. El modelo se almacena en el almacenamiento interno del teléfono.

3. **Modelo:** `gemma-2b-it-cpu-int8.bin` alojado en `NUMI12123/NUMI-gemma` en Hugging Face.

4. **Requisito mínimo:** Android con procesador de 64 bits, 3 GB RAM disponibles durante la inferencia (~45-60 segundos por respuesta en gama baja).

### Banco de preguntas MCQ

Para todos los grados existe un banco de 150 preguntas de selección múltiple en SQLite (10 preguntas × 5 materias × 3 grados). Las opciones se barajan aleatoriamente en cada sesión para que la respuesta correcta no siempre esté en la misma posición.

---

## Backend RAG API

El backend en Railway sirve los paquetes de conocimiento y actúa como fallback semántico cuando hay internet.

**URL:** una sola fuente en `frontend/lib/data/services/api_config.dart` (`--dart-define=API_BASE_URL=...`).

Ver [backend/README.md](backend/README.md) para documentación completa de endpoints, despliegue y configuración de Google Gemini.

---

## Sincronización multi-dispositivo

El sistema de sincronización offline-first garantiza que el progreso nunca se pierde:

```
Sin internet → progreso guardado en SQLite (sincronizado = 0)
Con internet → progreso subido al backend (PUT /api/v1/me/progreso)
Nuevo dispositivo → sincronizarAlLogin() restaura todo desde el backend
Conflicto → gana el mayor porcentaje (un niño nunca retrocede)
```

Los cambios de otros dispositivos se consultan cada 60 s con un `StreamProvider` y se aplican con la misma regla de fusión.

### Separación frontend / backend y de la persistencia

| Capa | Dónde vive | Qué guarda | Quién accede |
|------|-----------|-----------|--------------|
| Dispositivo | SQLite en `frontend/` | Progreso, perfil, base de conocimiento descargada | Solo la app |
| Servicio de usuarios | BD propia (`USERS_DATABASE_URL`) | Perfil y progreso por `uid` | Solo `/api/v1/me/*`, con token de Firebase |
| Servicio de contenido | Archivos `backend/knowledge_base/` (solo lectura) | Contenido educativo, sin datos personales | Público |
| Identidad | Firebase Auth | Credenciales | El backend solo valida el token; no guarda contraseñas |

El frontend ya **no** habla con ninguna base de datos remota: todo pasa por la API, que valida cada petición, aísla a cada usuario por su `uid` y limita el ritmo de uso. Un compromiso del servicio de contenido no expone datos personales, y la BD de usuarios puede vivir en un servidor distinto.

---

## Equipos

| Equipo | Responsabilidad |
|--------|----------------|
| **Ingeniería** | ViewModels, UseCases, Repositories, Services, RAG, SQLite, Firebase, backend |
| **Crosmedia** | Views, animaciones, paleta de colores, logo, mockups, assets de audio/imagen |



---

## Documentación adicional

| Documento | Descripción |
|-----------|-------------|
| [CLAUDE.md](frontend/CLAUDE.md) | Guía de arquitectura y reglas para el agente de IA |
| [Bitácoras de IA](bitacoras_lmunosrendon123@gmail.com/INDICE.md) | Registro de todas las sesiones de desarrollo con IA |
| [Backend README](backend/README.md) | Documentación del backend Python |

---

*Proyecto académico — Medellín, Colombia — 2026*  
*Desarrollado con asistencia de Claude Sonnet 4.6 (Anthropic)*

# Backend — Numi Educativa v4.0

API pública en Python (FastAPI) que sirve las bases de conocimiento offline para el asistente IA de la app Numi.  
Desde v3.0 integra **Google Gemini** (LLM gratuito) para generar respuestas naturales y adaptadas al grado del estudiante.

## Arquitectura: dos servicios, dos almacenes

```
app/main.py            ← ensambla, CORS, cabeceras de seguridad
├── app/content/       ← CONTENIDO/IA: público, solo lectura, sin datos personales
│                        almacén: backend/knowledge_base/*.json
└── app/users/         ← USUARIOS: perfil y progreso, autenticado
                         almacén: base de datos propia (USERS_DATABASE_URL)
```

`app.content` no importa nada de `app.users` y viceversa: se pueden desplegar por separado.

## Datos de usuario (requieren `Authorization: Bearer <ID token de Firebase>`)

| Método | URL | Descripción |
|--------|-----|-------------|
| GET/PUT | `/api/v1/me/perfil` | Perfil del estudiante autenticado |
| GET/PUT | `/api/v1/me/progreso` | Progreso; el PUT hace upsert en lote (máx. 500) y gana el mayor avance |
| DELETE | `/api/v1/me` | Borra perfil y progreso del usuario |

El dueño de los datos es siempre el `uid` del token verificado. Firebase Auth sigue siendo el proveedor de identidad; el backend no guarda contraseñas.

## Variables de entorno

| Variable | Defecto | Uso |
|----------|---------|-----|
| `FIREBASE_PROJECT_ID` | `rag-numi` | Audiencia esperada del token |
| `USERS_DATABASE_URL` | `sqlite:///data/usuarios.db` | BD de usuarios. En producción: PostgreSQL gestionado (`postgresql+psycopg://…`, instalar `psycopg[binary]`) o SQLite en un **volumen persistente** montado en `/app/data` |
| `GEMINI_API_KEY` | — | Activa el LLM |
| `FAISS_ENABLED` | `false` | Búsqueda semántica |
| `CORS_ORIGINS` | vacío | Orígenes web permitidos (la app móvil no lo necesita) |
| `TRUST_PROXY` | `false` | `true` detrás de Railway/nginx para el rate limit por IP |
| `RATE_IA_POR_MINUTO` / `RATE_USUARIOS_POR_MINUTO` | 20 / 60 | Límites por IP |
| `EXPONER_DOCS` | `false` | Publica `/docs` |

> Sin volumen o BD externa, el filesystem de Railway es efímero y los datos de usuario se perderían en cada despliegue.

## Migrar datos de Firestore (una sola vez)

Las cuentas creadas antes de esta versión tienen su progreso en Firestore. Este script lo copia a la base del backend; se puede repetir sin duplicar (el perfil no se pisa y el progreso conserva el mayor avance).

1. Firebase Console → ⚙️ Configuración del proyecto → **Cuentas de servicio** → *Generar nueva clave privada*. Guarda el `.json` **fuera del repositorio**.
2. La base de destino es la de producción: con PostgreSQL de Railway usa su URL **pública** (`DATABASE_PUBLIC_URL`) cambiando el inicio a `postgresql+psycopg://`.
3. En PowerShell:
   ```powershell
   cd backend
   pip install -r requirements-migracion.txt
   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\ruta\fuera-del-repo\clave.json"
   $env:USERS_DATABASE_URL = "postgresql+psycopg://usuario:clave@host:puerto/railway"
   python scripts/migrar_firestore.py --dry-run     # solo informa
   python scripts/migrar_firestore.py               # escribe
   ```
4. Al terminar, **borra la clave de servicio** (y revócala en la consola si ya no se necesita).

## Migrar de SQLite a PostgreSQL (una sola vez)

Si el backend ya guardó usuarios reales en SQLite (por ejemplo, con un volumen de Railway) antes de tener PostgreSQL, este script copia esos datos. Si la base en Railway todavía está vacía, este paso **no hace falta**: basta con apuntar `USERS_DATABASE_URL` a Postgres y redesplegar — las tablas se crean solas al arrancar.

Es seguro repetirlo (misma regla que el resto de la app: el perfil no se pisa, el progreso conserva el mayor avance). Verificado end-to-end contra un PostgreSQL real en Docker, además de con pruebas automáticas.

1. Consigue el archivo `.db` actual. Si el backend lo escribe en un volumen de Railway, descárgalo con la CLI de Railway; si lo tienes en un disco local de pruebas, usa esa ruta directamente.
2. En PowerShell:
   ```powershell
   cd backend
   .\venv\Scripts\Activate.ps1
   python scripts/migrar_sqlite_a_postgres.py `
     --origen "sqlite:///C:/ruta/a/usuarios.db" `
     --destino "postgresql+psycopg://usuario:clave@host:puerto/railway" `
     --dry-run     # solo informa

   python scripts/migrar_sqlite_a_postgres.py `
     --origen "sqlite:///C:/ruta/a/usuarios.db" `
     --destino "postgresql+psycopg://usuario:clave@host:puerto/railway"
   ```
3. Revisa el resumen (perfiles y progreso copiados) antes de dar por hecha la migración.

## Pruebas

```bash
pip install -r requirements-dev.txt
pytest -q
```

## Endpoints de contenido

| Método | URL | Descripción |
|--------|-----|-------------|
| GET  | `/` | Info general (versión, estado LLM, estado FAISS) |
| GET  | `/api/paquetes` | Lista todos los paquetes disponibles |
| GET  | `/api/paquetes/{materia}/info` | Metadata de un paquete |
| GET  | `/api/paquetes/{materia}` | **Descarga el ZIP** de una materia |
| POST | `/api/buscar_semantico` | Búsqueda semántica FAISS (devuelve entradas crudas) |
| POST | `/api/preguntar` | **Nuevo** — FAISS + Gemini → respuesta natural por grado |

**Materias válidas:** `matematicas`, `ciencias`, `espanol`, `ingles`, `sociales`

---

## Nuevo endpoint `/api/preguntar` (LLM)

### Request

```json
POST /api/preguntar
{
  "pregunta": "¿Qué es la fotosíntesis?",
  "materia":  "ciencias",
  "grado":    4
}
```

### Response

```json
{
  "pregunta":   "¿Qué es la fotosíntesis?",
  "materia":    "ciencias",
  "grado":      4,
  "texto":      "La fotosíntesis es el proceso que usan las plantas para fabricar su propio alimento...",
  "tema":       "fotosíntesis",
  "encontrado": true,
  "llm_usado":  true
}
```

- `llm_usado: true` → respuesta generada por Gemini usando el contexto recuperado.
- `llm_usado: false` → fallback al mejor resultado RAG (si Gemini no está configurado o falla).
- `encontrado: false` → no se encontró contexto relevante (pregunta fuera de la base de conocimiento).

---

## Configurar Google Gemini (gratis)

### 1. Obtener API Key en Google AI Studio

1. Ve a **[aistudio.google.com](https://aistudio.google.com)**
2. Inicia sesión con tu cuenta Google
3. Haz clic en **"Get API key"** → **"Create API key"**
4. Copia la clave generada (formato: `AIzaSy...`)

> El tier gratuito de Gemini 1.5 Flash incluye **1,500 solicitudes/día** y **1,000,000 tokens/minuto** — más que suficiente para esta app educativa.

### 2. Configurar la variable de entorno

**En Railway:**
1. Ve al servicio → pestaña **Variables**
2. Añade: `GEMINI_API_KEY` = `AIzaSy...` (tu clave)
3. El servicio se reiniciará automáticamente

**En Render:**
1. Ve al servicio → **Environment**
2. Añade la variable `GEMINI_API_KEY`

**Localmente:**
```bash
export GEMINI_API_KEY="AIzaSy..."
uvicorn main:app --reload --port 8000
```

**En Windows (CMD):**
```cmd
set GEMINI_API_KEY=AIzaSy...
uvicorn main:app --reload --port 8000
```

### 3. Modelo por defecto

El modelo predeterminado es `gemini-1.5-flash`. Puedes cambiarlo con la variable:

```
GEMINI_MODEL=gemini-1.5-flash    # predeterminado (recomendado, tier free)
GEMINI_MODEL=gemini-2.0-flash    # alternativa más reciente
```

---

## Comportamiento sin API Key (degradado)

Si `GEMINI_API_KEY` no está configurada o el paquete `google-generativeai` no está instalado:

- Los endpoints `/api/paquetes/*` y `/api/buscar_semantico` funcionan con normalidad.
- El endpoint `/api/preguntar` devuelve la respuesta directa del RAG (sin pasar por LLM), con `llm_usado: false`.
- La app Flutter sigue funcionando con su motor BM25 + TFLite local como fallback.

---

## Ejecutar localmente

```bash
cd backend
pip install -r requirements.txt
export GEMINI_API_KEY="AIzaSy..."   # opcional
export EXPONER_DOCS=true             # habilita /docs solo en desarrollo
uvicorn app.main:app --reload --port 8000
```

Abre: http://localhost:8000/docs

---

## Desplegar en Railway (recomendado)

1. Crea cuenta en https://railway.app
2. Nuevo proyecto → "Deploy from GitHub repo"
3. Selecciona este repositorio, carpeta `/backend`
4. Railway detecta el Dockerfile automáticamente
5. En Variables, añade `GEMINI_API_KEY` con tu clave de Google AI Studio
6. Copia la URL pública que genera Railway
7. Pégala en Flutter: `frontend/lib/data/services/api_config.dart` → `baseUrl` (o `--dart-define=API_BASE_URL=...`)

---

## Desplegar en Render (alternativa gratuita)

1. Crea cuenta en https://render.com
2. New → Web Service → Connect repo
3. Root Directory: `backend`
4. Build Command: `pip install -r requirements.txt`
5. Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
6. En Environment, añade `GEMINI_API_KEY`
7. Copia la URL y actualiza `ApiConfig.baseUrl` en el frontend

---

## Actualizar el contenido

Edita los archivos JSON en `knowledge_base/` y re-despliega.  
Los ZIPs se regeneran automáticamente y los índices FAISS se reconstruyen al reiniciar.

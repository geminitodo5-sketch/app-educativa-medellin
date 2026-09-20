"""Configuración del backend, leída de variables de entorno."""

import os


def _bool(nombre: str, defecto: bool = False) -> bool:
    return os.environ.get(nombre, str(defecto)).strip().lower() in ("1", "true", "yes")


def _lista(nombre: str) -> list[str]:
    return [x.strip() for x in os.environ.get(nombre, "").split(",") if x.strip()]


# ── Autenticación (Firebase Auth sigue siendo el proveedor de identidad) ─────
# El backend NO guarda contraseñas: solo valida el ID token que emite Firebase.
FIREBASE_PROJECT_ID = os.environ.get("FIREBASE_PROJECT_ID", "rag-numi").strip()

# ── Persistencia de datos de usuario (aislada del contenido) ─────────────────
# SQLite por defecto (archivo en un volumen propio). En producción usa una BD
# gestionada distinta del servidor de la API, p. ej.:
#   postgresql+psycopg://usuario:clave@host:5432/numi_usuarios
USERS_DATABASE_URL = os.environ.get("USERS_DATABASE_URL", "sqlite:///data/usuarios.db")

# ── Red ──────────────────────────────────────────────────────────────────────
# Orígenes CORS permitidos. La app móvil no usa CORS (no es navegador), así que
# por defecto NO se permite ningún origen web.
CORS_ORIGINS = _lista("CORS_ORIGINS")
# true solo detrás de un proxy de confianza (Railway, nginx) para leer X-Forwarded-For.
TRUST_PROXY = _bool("TRUST_PROXY", False)

# ── Límites de uso ───────────────────────────────────────────────────────────
RATE_IA_POR_MINUTO = int(os.environ.get("RATE_IA_POR_MINUTO", "20"))
RATE_USUARIOS_POR_MINUTO = int(os.environ.get("RATE_USUARIOS_POR_MINUTO", "60"))
MAX_PROGRESO_POR_REQUEST = 500

# ── Documentación interactiva (/docs) apagada por defecto en producción ──────
EXPONER_DOCS = _bool("EXPONER_DOCS", False)

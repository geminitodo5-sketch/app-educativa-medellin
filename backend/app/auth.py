"""Verificación de identidad: valida el ID token de Firebase Auth.

El usuario se identifica SIEMPRE por el `uid` del token verificado; nunca por
un identificador enviado en la URL o el cuerpo. Así un usuario no puede leer
ni escribir datos de otro.
"""

import requests as _requests
from cachecontrol import CacheControl
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.transport import requests as _g_requests
from google.oauth2 import id_token as _id_token

from app import config

_bearer = HTTPBearer(auto_error=False)

# Sesión con caché para no descargar los certificados públicos de Google en cada request.
_transport = _g_requests.Request(session=CacheControl(_requests.Session()))


def _verificar(token: str) -> dict:
    return _id_token.verify_firebase_token(
        token, _transport, audience=config.FIREBASE_PROJECT_ID
    )


def usuario_actual(
    cred: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> str:
    """Devuelve el uid de Firebase del solicitante o responde 401."""
    if cred is None or cred.scheme.lower() != "bearer":
        raise HTTPException(401, "Falta el token de autenticación.",
                            headers={"WWW-Authenticate": "Bearer"})
    try:
        claims = _verificar(cred.credentials)
    except Exception:
        claims = None
    uid = (claims or {}).get("user_id") or (claims or {}).get("sub")
    if not uid:
        raise HTTPException(401, "Token inválido o vencido.",
                            headers={"WWW-Authenticate": "Bearer"})
    return uid

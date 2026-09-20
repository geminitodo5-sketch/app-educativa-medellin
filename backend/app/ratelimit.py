"""Límite de peticiones por cliente (ventana deslizante en memoria).

Suficiente para una sola instancia; con varias réplicas usar un almacén
compartido (Redis) o el rate limit del proxy.
"""

import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request

from app import config


def _ip_cliente(request: Request) -> str:
    if config.TRUST_PROXY:
        adelante = request.headers.get("x-forwarded-for", "")
        if adelante:
            return adelante.split(",")[0].strip()
    return request.client.host if request.client else "desconocido"


class LimitadorVentana:
    def __init__(self, maximo, ventana_s: float = 60.0):
        self._maximo = maximo  # callable → permite leer config en cada llamada
        self._ventana = ventana_s
        self._hits: dict[str, deque] = defaultdict(deque)

    def __call__(self, request: Request) -> None:
        ahora = time.monotonic()
        clave = _ip_cliente(request)
        q = self._hits[clave]
        while q and ahora - q[0] > self._ventana:
            q.popleft()
        if len(q) >= self._maximo():
            raise HTTPException(429, "Demasiadas solicitudes. Espera un momento.",
                                headers={"Retry-After": "60"})
        q.append(ahora)
        if len(self._hits) > 10_000:  # evita crecimiento sin límite
            for k in [k for k, v in self._hits.items() if not v]:
                del self._hits[k]


limitar_ia = LimitadorVentana(lambda: config.RATE_IA_POR_MINUTO)
limitar_usuarios = LimitadorVentana(lambda: config.RATE_USUARIOS_POR_MINUTO)

from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app import config

_MATERIA = r"^[a-zñáéíóú_]{2,30}$"


class PerfilIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    nombre: str = Field(min_length=1, max_length=60)
    grado: int = Field(ge=1, le=5)
    personaje: str = Field(min_length=1, max_length=30)
    email: Optional[str] = Field(default=None, max_length=254)
    edad: Optional[int] = Field(default=None, ge=1, le=99)
    genero: Optional[str] = Field(default=None, max_length=20)
    fecha_registro: Optional[str] = Field(default=None, max_length=40)


class PerfilOut(PerfilIn):
    model_config = ConfigDict(from_attributes=True)


class ProgresoItem(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")

    grado: int = Field(ge=1, le=5)
    materia: str = Field(pattern=_MATERIA)
    actividad: str = Field(min_length=1, max_length=120)
    porcentaje: float = Field(ge=0, le=100)
    intentos: int = Field(default=0, ge=0, le=100_000)
    ultima_vez: Optional[str] = Field(default=None, max_length=40)


class ProgresoLote(BaseModel):
    model_config = ConfigDict(extra="forbid")

    items: list[ProgresoItem] = Field(max_length=config.MAX_PROGRESO_POR_REQUEST)

from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.users.database import Base


def _ahora() -> datetime:
    return datetime.now(timezone.utc)


class Perfil(Base):
    __tablename__ = "perfiles"

    uid: Mapped[str] = mapped_column(String(128), primary_key=True)  # uid de Firebase
    nombre: Mapped[str] = mapped_column(String(60))
    grado: Mapped[int] = mapped_column(Integer)
    personaje: Mapped[str] = mapped_column(String(30))
    email: Mapped[str | None] = mapped_column(String(254), nullable=True)
    edad: Mapped[int | None] = mapped_column(Integer, nullable=True)
    genero: Mapped[str | None] = mapped_column(String(20), nullable=True)
    fecha_registro: Mapped[str | None] = mapped_column(String(40), nullable=True)
    actualizado: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_ahora, onupdate=_ahora
    )

    progreso: Mapped[list["Progreso"]] = relationship(
        back_populates="perfil", cascade="all, delete-orphan", passive_deletes=True
    )


class Progreso(Base):
    __tablename__ = "progreso"

    uid: Mapped[str] = mapped_column(
        String(128), ForeignKey("perfiles.uid", ondelete="CASCADE"), primary_key=True
    )
    grado: Mapped[int] = mapped_column(Integer, primary_key=True)
    materia: Mapped[str] = mapped_column(String(30), primary_key=True)
    actividad: Mapped[str] = mapped_column(String(120), primary_key=True)
    porcentaje: Mapped[float] = mapped_column(Float, default=0.0)
    intentos: Mapped[int] = mapped_column(Integer, default=0)
    ultima_vez: Mapped[str | None] = mapped_column(String(40), nullable=True)
    actualizado: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_ahora, onupdate=_ahora
    )

    perfil: Mapped[Perfil] = relationship(back_populates="progreso")

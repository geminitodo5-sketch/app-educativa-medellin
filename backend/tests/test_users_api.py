import pytest
from fastapi.testclient import TestClient

from app import auth, config
from app.main import app
from app.users import database

@pytest.fixture()
def cliente(monkeypatch):
    def falso(token: str) -> dict:
        if not token.startswith("uid-"):
            raise ValueError("token inválido")
        return {"user_id": token}

    monkeypatch.setattr(auth, "_verificar", falso)
    database.Base.metadata.drop_all(database.engine)
    with TestClient(app) as c:
        yield c


def h(uid: str) -> dict:
    return {"Authorization": f"Bearer {uid}"}


PERFIL = {"nombre": "Ana", "grado": 3, "personaje": "pollito"}
ITEM = {"grado": 3, "materia": "matematicas", "actividad": "sumar", "porcentaje": 60, "intentos": 2}


def test_sin_token_401(cliente):
    assert cliente.get("/api/v1/me/perfil").status_code == 401


def test_token_invalido_401(cliente):
    assert cliente.get("/api/v1/me/perfil", headers=h("malo")).status_code == 401


def test_perfil_crud(cliente):
    r404 = cliente.get("/api/v1/me/perfil", headers=h("uid-a"))
    assert r404.status_code == 404
    assert r404.json()["detail"]["codigo"] == "perfil_no_existe"
    r = cliente.put("/api/v1/me/perfil", json=PERFIL, headers=h("uid-a"))
    assert r.status_code == 200 and r.json()["nombre"] == "Ana"
    r = cliente.put("/api/v1/me/perfil", json={**PERFIL, "nombre": "Ana B"}, headers=h("uid-a"))
    assert r.json()["nombre"] == "Ana B"


def test_progreso_requiere_perfil(cliente):
    r = cliente.put("/api/v1/me/progreso", json={"items": [ITEM]}, headers=h("uid-a"))
    assert r.status_code == 409


def test_progreso_gana_mayor_avance(cliente):
    cliente.put("/api/v1/me/perfil", json=PERFIL, headers=h("uid-a"))
    cliente.put("/api/v1/me/progreso", json={"items": [ITEM]}, headers=h("uid-a"))
    r = cliente.put("/api/v1/me/progreso",
                    json={"items": [{**ITEM, "porcentaje": 30, "intentos": 5}]}, headers=h("uid-a"))
    fila = r.json()[0]
    assert fila["porcentaje"] == 60 and fila["intentos"] == 5
    assert len(cliente.get("/api/v1/me/progreso", headers=h("uid-a")).json()) == 1


def test_aislamiento_entre_usuarios(cliente):
    cliente.put("/api/v1/me/perfil", json=PERFIL, headers=h("uid-a"))
    cliente.put("/api/v1/me/progreso", json={"items": [ITEM]}, headers=h("uid-a"))
    assert cliente.get("/api/v1/me/progreso", headers=h("uid-b")).json() == []
    assert cliente.get("/api/v1/me/perfil", headers=h("uid-b")).status_code == 404


@pytest.mark.parametrize("malo", [
    {**ITEM, "porcentaje": 101},
    {**ITEM, "grado": 9},
    {**ITEM, "materia": "x; DROP TABLE"},
    {**ITEM, "extra": 1},
])
def test_validacion_progreso(cliente, malo):
    cliente.put("/api/v1/me/perfil", json=PERFIL, headers=h("uid-a"))
    r = cliente.put("/api/v1/me/progreso", json={"items": [malo]}, headers=h("uid-a"))
    assert r.status_code == 422


def test_lote_demasiado_grande(cliente):
    cliente.put("/api/v1/me/perfil", json=PERFIL, headers=h("uid-a"))
    items = [{**ITEM, "actividad": f"a{i}"} for i in range(config.MAX_PROGRESO_POR_REQUEST + 1)]
    assert cliente.put("/api/v1/me/progreso", json={"items": items}, headers=h("uid-a")).status_code == 422


def test_borrar_mis_datos(cliente):
    cliente.put("/api/v1/me/perfil", json=PERFIL, headers=h("uid-a"))
    cliente.put("/api/v1/me/progreso", json={"items": [ITEM]}, headers=h("uid-a"))
    assert cliente.delete("/api/v1/me", headers=h("uid-a")).status_code == 204
    assert cliente.get("/api/v1/me/perfil", headers=h("uid-a")).status_code == 404
    assert cliente.get("/api/v1/me/progreso", headers=h("uid-a")).json() == []


def test_contenido_publico_sigue_funcionando(cliente):
    assert cliente.get("/api/paquetes").json()["total"] == 5
    assert cliente.get("/api/paquetes/matematicas").status_code == 200
    assert cliente.get("/api/paquetes/otra").status_code == 404

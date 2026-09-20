import os
import sys
import tempfile

# BD temporal y aislada para las pruebas (antes de importar la app)
_dir = tempfile.mkdtemp(prefix="numi_test_")
os.environ["USERS_DATABASE_URL"] = "sqlite:///" + os.path.join(_dir, "usuarios.db").replace("\\", "/")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-descarga el modelo fastembed (|| true → build no falla si hay error de red)
ENV FASTEMBED_CACHE_PATH=/app/fastembed_cache
RUN python -c "\
from fastembed import TextEmbedding; \
list(TextEmbedding(model_name='sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2').embed(['warmup']))" \
    || echo "[INFO] Modelo fastembed no pre-descargado. Se descargará al arrancar."

# Usuario sin privilegios: si la app se compromete, no es root dentro del contenedor.
RUN useradd --create-home --uid 10001 numi \
    && mkdir -p /app/data /app/packages \
    && chown -R numi /app
COPY --chown=numi . .
USER numi

# Los datos de usuario viven en /app/data. No se declara VOLUME aquí (Railway
# lo prohíbe): monta un volumen de Railway en /app/data, o usa PostgreSQL con
# USERS_DATABASE_URL.
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

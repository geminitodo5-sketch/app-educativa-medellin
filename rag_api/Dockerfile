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

COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

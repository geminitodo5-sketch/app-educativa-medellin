FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-descarga del modelo fastembed durante el build para evitar delay en cold-start
ENV FASTEMBED_CACHE_PATH=/app/fastembed_cache
RUN python -c "\
from fastembed import TextEmbedding; \
list(TextEmbedding(model_name='sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2').embed(['warmup']))"

COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

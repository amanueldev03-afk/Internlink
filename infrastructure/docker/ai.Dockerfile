FROM python:3.12-slim
WORKDIR /workspace
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    PIP_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cpu
COPY services/ai-service/pyproject.toml ./services/ai-service/
COPY services/ai-service/app ./services/ai-service/app
COPY services/ai-service/scripts ./services/ai-service/scripts
RUN python -m pip install --no-cache-dir --upgrade pip && \
    python -m pip install --no-cache-dir ./services/ai-service
WORKDIR /workspace/services/ai-service
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Multi-stage build für optimierte Größe
FROM python:3.11-slim as builder

# System dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim

# System dependencies für Runtime
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r appuser && useradd -r -g appuser appuser

# Python dependencies von builder stage kopieren
COPY --from=builder /root/.local /home/appuser/.local

# App code kopieren
WORKDIR /app
COPY . .

# Ownership ändern
RUN chown -R appuser:appuser /app

# Zu non-root user wechseln
USER appuser

# PATH für lokale Python packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Port exposen
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# App starten
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

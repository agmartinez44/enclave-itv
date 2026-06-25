FROM python:3.8-slim AS build
WORKDIR /app
COPY ./app/src/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.8-slim
RUN useradd -m appuser
WORKDIR /app
COPY --from=build /install /usr/local
COPY ./app/src/app.py .
RUN chown -R appuser:appuser /app
USER appuser
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz', timeout=5)"
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]

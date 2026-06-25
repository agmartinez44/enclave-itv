# App

Small Flask HTTP service for the Kubernetes challenge.

## Endpoints

- `GET /healthz` → `200` with `{"SYS_ENV":"hello-enclaive"}` (value read from the `SYS_ENV` env var)
- `GET /metrics` → Prometheus metrics, including the `healthz_requests_total` counter

## Run locally

```bash
cd app/src
pip install -r requirements.txt
SYS_ENV=hello-enclaive gunicorn --bind 0.0.0.0:8080 app:app

curl http://127.0.0.1:8080/healthz
curl http://127.0.0.1:8080/metrics
```

## Docker

Build from the repository root:

```bash
SHA=$(git rev-parse --short HEAD)
docker build -t enclave-itv:$SHA -t enclave-itv:latest -f ./app/Dockerfile .
```

Multi-stage build on `python:3.8-slim`, runs as a non-root user, and defines a container `HEALTHCHECK` against `/healthz`. Final image is ~49 MB.

# Enclave ITV Kubernetes Challenge

A small Flask HTTP API, containerised and deployed to Kubernetes with Helm. The Helm chart starts from the standard `helm create` layout so the structure is familiar and quick to review.

## Requirements

Docker, kind, kubectl, Helm, curl.

## Build the image

Create the cluster if it does not exist yet:

```bash
kind create cluster --config infrastructure/kind-cluster.yaml
```

Build and load the image into kind:

```bash
./pipeline.sh
```

This tags the image `enclave-itv:<git-sha>` and `enclave-itv:latest` and loads both into the kind nodes.

## Deploy

```bash
./setup.sh
```

`setup.sh` installs kube-prometheus-stack, HashiCorp Vault (dev mode), and the External Secrets Operator, then deploys the app to `dev` and `prod`. It also writes `SYS_ENV=hello-enclaive` to Vault at `secret/app` and creates the `vault-token` secret in both namespaces.

## Access the app

```bash
kubectl -n dev port-forward svc/app-dev 8080:8080
curl http://127.0.0.1:8080/healthz   # {"SYS_ENV":"hello-enclaive"}
curl http://127.0.0.1:8080/metrics   # Prometheus metrics, incl. healthz_requests_total
```

## Hidden challenge: the tainted prod node

`setup.sh` taints one worker as the prod-only node and labels it:

```bash
kubectl taint nodes kind-worker key=critical:NoSchedule --overwrite
kubectl label nodes kind-worker stage=prod --overwrite
```

`values.prod.yaml` pins prod pods to that node and tolerates the taint:

```yaml
nodeSelector:
  stage: prod
tolerations:
  - key: "key"
    operator: "Equal"
    value: "critical"
    effect: "NoSchedule"
```

`values.dev.yaml` sets neither, so the `NoSchedule` taint keeps dev pods off the prod node. Verified placement: both prod pods land on `kind-worker`, dev runs on the other worker.

## Rollout safety

The Deployment uses `RollingUpdate` with `maxUnavailable: 0` and `maxSurge: 1`, so a new revision only takes traffic once a fresh pod is ready. Both releases install with `--atomic --wait --timeout 180s`: a rollout that fails to become healthy is rolled back automatically. See `OPERATIONS.md` for manual rollback.

## Tear down

```bash
kind delete cluster --name kind   # removes cluster, releases, Vault data, monitoring
docker rmi enclave-itv:latest     # optional: drop the host image
```

## Estimated time

| Task | Time |
| --- | ---: |
| App Dockerfile + service | 35–50 min |
| Helm chart + dev/prod values | 60–90 min |
| Rollout strategy & rollback | 30–45 min |
| Observability / metrics stack | 60–90 min |
| Vault + External Secrets | 45–75 min |
| Backup & restore docs | 25–40 min |
| README & hidden challenge | 35–60 min |
| End-to-end testing & fixes | 60–120 min |

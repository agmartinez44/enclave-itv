# Operations

## Deploy

```bash
kind create cluster --config infrastructure/kind-cluster.yaml
./pipeline.sh   # build + load image
./setup.sh      # platform services + app (dev and prod)
```

`setup.sh` reuses an existing cluster if one is already running.

## Verify health

```bash
kubectl -n dev rollout status deployment/app-dev
kubectl -n prod rollout status deployment/app-prod

kubectl -n dev port-forward svc/app-dev 8080:8080
curl http://127.0.0.1:8080/healthz   # {"SYS_ENV":"hello-enclaive"}
```

## Metrics

```bash
kubectl -n dev port-forward svc/app-dev 8080:8080
curl http://127.0.0.1:8080/metrics
```

The app exposes a Prometheus counter, `healthz_requests_total`.

## Monitoring

kube-prometheus-stack runs in the `monitoring` namespace.

```bash
helm list -n monitoring
kubectl get pods -n monitoring
kubectl get prometheusrule -A
```

The chart ships a `KubernetesPodNotHealthy` alert that fires when a pod stays in `Pending`, `Unknown`, or `Failed` for 15 minutes. Prometheus discovers it via the `release: monitoring` label on the PrometheusRule.

## Rollback

Deploys run with `--atomic --wait`, so a rollout that does not become ready before the timeout is rolled back automatically.

Manual rollback with Helm:

```bash
helm history app-prod -n prod
helm rollback app-prod <REVISION> -n prod --wait
```

Or at the Deployment level:

```bash
kubectl -n prod rollout history deployment/app-prod
kubectl -n prod rollout undo deployment/app-prod
kubectl -n prod rollout status deployment/app-prod
```

## Secrets

Vault runs in dev mode. External Secrets reads `secret/app` from Vault and writes the `app-secret` Kubernetes Secret consumed by the Deployment.

```bash
kubectl -n vault exec vault-0 -- vault kv put secret/app SYS_ENV=hello-enclaive

kubectl -n dev get externalsecret
kubectl -n dev get secret app-secret
```

## Node scheduling

```bash
kubectl -n prod get pods -o wide   # both pods on kind-worker (tainted)
kubectl -n dev get pods -o wide    # dev avoids the tainted node
```

Prod uses `nodeSelector.stage=prod` plus a matching toleration; dev has neither.

## Backup and restore

For this local setup, backup means preserving declarative state and Vault data:

```bash
helm get values app-dev -n dev -o yaml
helm get values app-prod -n prod -o yaml
kubectl -n vault exec vault-0 -- vault kv get -format=json secret/app
```

Everything else lives in Git (source, Dockerfile, chart, values, scripts). Restore is a clean redeploy:

```bash
kind create cluster --config infrastructure/kind-cluster.yaml
./pipeline.sh
./setup.sh
```

In production, Vault would not run in dev mode: it would need persistent storage, unseal/recovery procedures, access policies, and a tested backup of its storage backend.

## Tear down

```bash
kind delete cluster --name kind
```

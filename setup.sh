#!/bin/bash
set -euo pipefail

# REQUIREMENTS: kubectl, kind, docker, helm

if ! kind get clusters | grep -qx kind; then
  kind create cluster --config infrastructure/kind-cluster.yaml
fi
kubectl config use-context kind-kind

kubectl taint nodes kind-worker key=critical:NoSchedule --overwrite
kubectl label nodes kind-worker stage=prod --overwrite

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo add hashicorp https://helm.releases.hashicorp.com --force-update
helm repo add external-secrets https://charts.external-secrets.io --force-update
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
helm upgrade --install vault hashicorp/vault --namespace vault --create-namespace --set "server.dev.enabled=true" --set "server.image.tag=1.15.6" --set "injector.agentImage.tag=1.15.6"
helm upgrade --install external-secrets external-secrets/external-secrets --namespace external-secrets --create-namespace --set "installCRDs=true"

kubectl -n vault wait --for=condition=Ready pod/vault-0 --timeout=180s
kubectl -n external-secrets rollout status deployment/external-secrets --timeout=180s
kubectl -n external-secrets rollout status deployment/external-secrets-webhook --timeout=180s
kubectl -n external-secrets rollout status deployment/external-secrets-cert-controller --timeout=180s

kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
kubectl -n dev create secret generic vault-token --from-literal=token=root --dry-run=client -o yaml | kubectl apply -f -
kubectl -n prod create secret generic vault-token --from-literal=token=root --dry-run=client -o yaml | kubectl apply -f -
kubectl -n vault exec vault-0 -- vault kv put secret/app SYS_ENV=hello-enclaive

helm upgrade --install app-dev charts/app -f charts/app/values.dev.yaml -n dev --atomic --wait --timeout 180s
helm upgrade --install app-prod charts/app -f charts/app/values.prod.yaml -n prod --atomic --wait --timeout 180s

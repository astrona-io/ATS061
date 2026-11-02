#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
lab_directory="$(cd "$(dirname "$0")/.." && pwd)"
node_name="astro-ats-061-lab-040-01-01-control-plane"
worker_name="astro-ats-061-lab-040-01-01-worker"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
manifest_path="$(mktemp)"
curl --fail --silent --show-error --location --max-time 120 'https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.4/manifests/install.yaml' -o "$manifest_path"
python3 - "$manifest_path" <<'CHECKSUM'
import hashlib,sys
assert hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest() == '1feb02cc7bacf3a379da58b0ca8c6f07d18288cd04d531dabd08816375e5e010', 'Controller manifest checksum differs'
CHECKSUM
kubectl apply --server-side -n argocd -f "$manifest_path"
rm -f "$manifest_path"
kubectl -n argocd scale deployment/argocd-dex-server deployment/argocd-notifications-controller --replicas=0
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
kubectl apply -f "$lab_directory/bootstrap/manifests/start.yaml"
kubectl -n starfleet rollout status deployment/probe --timeout=180s
kubectl -n starfleet wait --for=condition=Ready pod/shuttle --timeout=120s
kubectl -n outpost wait --for=condition=Ready pod/drifter --timeout=120s
kubectl apply -f "$lab_directory/bootstrap/manifests/git.yaml"
kubectl -n argocd rollout status deployment/git-source --timeout=180s

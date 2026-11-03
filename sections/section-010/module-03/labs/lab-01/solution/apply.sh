#!/usr/bin/env bash
# Reference solution. UNTESTED.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-010-03-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/application-bridge-cam.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/bridge-cam --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/bridge-cam --timeout=240s

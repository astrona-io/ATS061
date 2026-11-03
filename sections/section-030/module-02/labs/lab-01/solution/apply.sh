#!/usr/bin/env bash
# Reference solution. UNTESTED: never run against a cluster.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-030-02-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/application-probe-prod.yaml"
kubectl apply -f "$solution_directory/application-probe-dev.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/probe-prod --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-prod --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/probe-dev --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-dev --timeout=240s

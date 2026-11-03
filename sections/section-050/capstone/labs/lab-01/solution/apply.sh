#!/usr/bin/env bash
# Reference solution. UNTESTED: never run against a cluster.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-050" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/application-ops-bridge.yaml"
kubectl apply -f "$solution_directory/application-fleet-root.yaml"
kubectl apply -f "$solution_directory/applicationset-fleet-envs.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/ops-bridge --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/beta --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-prod --timeout=300s

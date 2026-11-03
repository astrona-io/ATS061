#!/usr/bin/env bash
# Reference solution. UNTESTED: never run against a cluster.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-040" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/application-fleet-chart.yaml"
kubectl apply -f "$solution_directory/application-bridge-dev.yaml"
kubectl apply -f "$solution_directory/application-bridge-prod.yaml"
for a in fleet-chart bridge-dev bridge-prod; do
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/$a --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/$a --timeout=240s
done

#!/usr/bin/env bash
# Reference solution. UNTESTED: never run against a cluster.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-030" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/project-bridge.yaml"
kubectl apply -f "$solution_directory/application-probe-chart.yaml"
kubectl apply -f "$solution_directory/application-fleet.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-chart --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/alpha --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/beta --timeout=240s

#!/usr/bin/env bash
# Reference solution. UNTESTED: never run against a cluster.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-02-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/application-fleet-root.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/fleet-root --timeout=300s

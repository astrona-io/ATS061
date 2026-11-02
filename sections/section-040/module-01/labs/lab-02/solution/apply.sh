#!/usr/bin/env bash
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-02" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
lab_directory="$(cd "$(dirname "$0")/.." && pwd)"
solution_directory="$lab_directory/solution"
node_name="astro-ats-061-lab-040-01-02-control-plane"
worker_name="astro-ats-061-lab-040-01-02-worker"

kubectl apply -f "$solution_directory/application-mission.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s

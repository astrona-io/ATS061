#!/usr/bin/env bash
# Reference solution. UNTESTED: never run against a cluster.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-020" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/application-main-deck.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/main-deck --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/main-deck --timeout=240s
kubectl apply -f "$solution_directory/project-freeze.yaml"
kubectl apply -f "$solution_directory/application-cargo-bay.yaml"
kubectl apply -f "$solution_directory/application-fleet-release.yaml"
kubectl config set-context --current --namespace=argocd
argocd login --core
argocd app sync fleet-release --core
argocd app sync fleet-release --revision release --core
first_id="$(kubectl -n argocd get application fleet-release -o jsonpath='{.status.history[0].id}')"
argocd app rollback fleet-release "$first_id" --core

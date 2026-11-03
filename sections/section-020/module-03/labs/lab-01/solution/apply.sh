#!/usr/bin/env bash
# Reference solution. UNTESTED: never run against a cluster.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-03-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/project-maintenance.yaml"
kubectl apply -f "$solution_directory/application-frozen.yaml"
kubectl apply -f "$solution_directory/application-release-train.yaml"
kubectl config set-context --current --namespace=argocd
argocd login --core
argocd app sync release-train --core
argocd app sync release-train --revision release --core
first_id="$(kubectl -n argocd get application release-train -o jsonpath='{.status.history[0].id}')"
argocd app rollback release-train "$first_id" --core

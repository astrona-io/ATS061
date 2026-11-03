#!/usr/bin/env bash
# Reference solution. UNTESTED.
set -euo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-010" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
solution_directory="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$solution_directory/applications.yaml"
for application in flight-deck hangar-cam mission-log; do
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/$application --timeout=240s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/$application --timeout=240s
done
repo_server_pod="$(kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-repo-server -o jsonpath='{.items[0].metadata.name}')"
revision="$(kubectl -n argocd get application flight-deck -o jsonpath='{.status.sync.revision}')"
kubectl -n argocd create configmap status-report --dry-run=client -o yaml \
  --from-literal=repo-server-pod="$repo_server_pod" \
  --from-literal=controller-kind=StatefulSet \
  --from-literal=flight-deck-revision="$revision" | kubectl apply -f -

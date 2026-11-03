#!/usr/bin/env bash
# Check: Application mission is Synced, Healthy and built by Kustomize
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-02" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application mission >/dev/null 2>&1 || fail "Application mission not found"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=90s >/dev/null 2>&1 || fail "Application mission is not Synced"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=90s >/dev/null 2>&1 || fail "Application mission is not Healthy"
[[ "$(app_field mission '{.status.sourceType}')" == "Kustomize" ]] || fail "status.sourceType must be Kustomize"
echo "PASS: Application mission is Synced, Healthy and built by Kustomize"

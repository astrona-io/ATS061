#!/usr/bin/env bash
# Check: Application fleet-chart is Synced, Healthy and rendered by Helm
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application fleet-chart >/dev/null 2>&1 || fail "Application fleet-chart not found"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/fleet-chart --timeout=90s >/dev/null 2>&1 || fail "Application fleet-chart is not Synced"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/fleet-chart --timeout=90s >/dev/null 2>&1 || fail "Application fleet-chart is not Healthy"
[[ "$(app_field fleet-chart '{.status.sourceType}')" == "Helm" ]] || fail "status.sourceType must be Helm"
echo "PASS: Application fleet-chart is Synced, Healthy and rendered by Helm"

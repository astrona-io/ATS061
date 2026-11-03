#!/usr/bin/env bash
# Check: The chart keeps its own namespace: objects are in starfleet, none in outpost
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n starfleet get service git-probe >/dev/null 2>&1 || fail "Service git-probe not found in starfleet"
kubectl -n outpost get deployment git-probe >/dev/null 2>&1 && fail "Deployment git-probe must not exist in outpost"
[[ -z "$(kubectl -n outpost get deployments -o name 2>/dev/null)" ]] || fail "outpost must hold no Deployment"
echo "PASS: The chart keeps its own namespace: objects are in starfleet, none in outpost"

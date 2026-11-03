#!/usr/bin/env bash
# Check: The unprefixed base objects do not exist and the prefixed Service does
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-02" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n starfleet get deployment git-probe >/dev/null 2>&1 && fail "Deployment git-probe from the base must not exist"
kubectl -n starfleet get service prod-git-probe >/dev/null 2>&1 || fail "Service prod-git-probe not found"
echo "PASS: The unprefixed base objects do not exist and the prefixed Service does"

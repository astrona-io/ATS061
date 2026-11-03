#!/usr/bin/env bash
# Check: ConfigMap, Deployment and Service of wave-app exist
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n starfleet get configmap wave-config >/dev/null 2>&1 || fail "ConfigMap wave-config is missing"
kubectl -n starfleet get deployment wave-app >/dev/null 2>&1 || fail "Deployment wave-app is missing"
kubectl -n starfleet get service wave-app >/dev/null 2>&1 || fail "Service wave-app is missing"
wait_until 30 test "$(kubectl -n starfleet get deployment wave-app -o jsonpath='{.status.availableReplicas}')" = 1 || fail "Deployment wave-app is not available"
echo "PASS: ConfigMap, Deployment and Service of wave-app exist"

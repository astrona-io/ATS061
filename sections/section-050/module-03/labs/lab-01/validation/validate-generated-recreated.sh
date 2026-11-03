#!/usr/bin/env bash
# Check: A deleted generated Application is created again
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
old_uid="$(app_field probe-dev '{.metadata.uid}')"
[[ -n "$old_uid" ]] || fail "Application probe-dev does not exist"
kubectl -n argocd patch application probe-dev --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1
kubectl -n argocd delete application probe-dev --wait=true --timeout=60s >/dev/null 2>&1 || fail "could not delete probe-dev"
dev_is_new() { local now; now="$(kubectl -n argocd get application probe-dev -o jsonpath='{.metadata.uid}' 2>/dev/null)"; test -n "$now" && test "$now" != "$old_uid"; }
wait_until 30 dev_is_new || fail "the ApplicationSet controller did not create probe-dev again within 90 seconds"
echo "PASS: A deleted generated Application is created again"

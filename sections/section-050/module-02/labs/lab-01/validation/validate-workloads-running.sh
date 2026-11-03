#!/usr/bin/env bash
# Check: Both child Applications are Synced and Healthy and their Deployments are available
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
for child in alpha beta; do
  wait_until 40 test "$(app_field "$child" '{.status.sync.status}')" = Synced || fail "Application $child is not Synced"
  wait_until 40 test "$(app_field "$child" '{.status.health.status}')" = Healthy || fail "Application $child is not Healthy"
  [[ "$(kubectl -n starfleet get deployment "$child" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)" == "1" ]] || fail "Deployment $child has no available replica"
done
echo "PASS: Both child Applications are Synced and Healthy and their Deployments are available"

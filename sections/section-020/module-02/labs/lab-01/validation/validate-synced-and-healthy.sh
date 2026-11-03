#!/usr/bin/env bash
# Check: Application ordered is Synced and Healthy
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_until 30 test "$(app_field ordered '{.status.sync.status}')" = Synced || fail "Application is not Synced"
wait_until 30 test "$(app_field ordered '{.status.health.status}')" = Healthy || fail "Application is not Healthy"
echo "PASS: Application ordered is Synced and Healthy"

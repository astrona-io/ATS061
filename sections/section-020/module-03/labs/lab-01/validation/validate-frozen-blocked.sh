#!/usr/bin/env bash
# Check: The deny window blocked the automated sync of frozen
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_until 20 test "$(app_field frozen '{.status.sync.status}')" = OutOfSync || fail "Application frozen is not OutOfSync"
[[ -z "$(app_field frozen '{.status.operationState.phase}')" ]] || fail "a sync operation exists, so the window did not block the sync"
if kubectl -n starfleet get deployment alpha >/dev/null 2>&1; then
  fail "Deployment alpha exists, so a sync was not blocked"
fi
echo "PASS: The deny window blocked the automated sync of frozen"

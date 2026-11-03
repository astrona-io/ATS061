#!/usr/bin/env bash
# Check: alpha and beta exist and fleet-root owns them
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_until 30 test "$(app_field fleet-root '{.status.sync.status}')" = Synced || fail "Application fleet-root is not Synced"
for child in alpha beta; do
  wait_until 30 kubectl -n argocd get application "$child" || fail "Application $child does not exist"
  track="$(app_field "$child" '{.metadata.annotations.argocd\.argoproj\.io/tracking-id}')"
  [[ "$track" == fleet-root:* ]] || fail "Application $child is not owned by fleet-root"
done
echo "PASS: alpha and beta exist and fleet-root owns them"

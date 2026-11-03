#!/usr/bin/env bash
# Check: A replica count set by hand stays on ops-bridge and the Application stays Synced
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-050" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_until 40 test "$(app_field ops-bridge '{.status.sync.status}')" = Synced || fail "Application ops-bridge is not Synced"
wait_until 40 test "$(app_field ops-bridge '{.status.health.status}')" = Healthy || fail "Application ops-bridge is not Healthy"
kubectl -n starfleet scale deployment git-probe --replicas=4 >/dev/null 2>&1 || fail "could not scale git-probe"
for i in 1 2 3 4 5 6 7 8; do
  sleep 3
  [[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)" == "4" ]] || fail "Argo CD reverted the replica count set by hand"
done
[[ "$(app_field ops-bridge '{.status.sync.status}')" == "Synced" ]] || fail "Application ops-bridge is not Synced after the replica change"
echo "PASS: A replica count set by hand stays on ops-bridge and the Application stays Synced"

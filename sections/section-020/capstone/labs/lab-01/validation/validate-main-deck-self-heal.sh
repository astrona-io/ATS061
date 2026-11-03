#!/usr/bin/env bash
# Check: main-deck repairs a manual change of wave-app
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-020" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field main-deck '{.spec.syncPolicy.automated.selfHeal}')" == "true" ]] || fail "automated selfHeal must be true"
kubectl -n starfleet scale deployment wave-app --replicas=3 >/dev/null 2>&1 || fail "could not scale wave-app"
wait_until 25 test "$(kubectl -n starfleet get deployment wave-app -o jsonpath='{.spec.replicas}' 2>/dev/null)" = 1 || fail "wave-app was not set back to 1 replica"
echo "PASS: main-deck repairs a manual change of wave-app"

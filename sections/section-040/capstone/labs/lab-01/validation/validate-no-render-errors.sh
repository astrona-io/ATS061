#!/usr/bin/env bash
# Check: None of the three Applications reports a ComparisonError
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-040" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
for a in fleet-chart bridge-dev bridge-prod; do
  kubectl -n argocd get application "$a" >/dev/null 2>&1 || fail "Application $a not found"
  kubectl -n argocd get application "$a" -o json | python3 -c '
import json,sys
c=json.load(sys.stdin).get("status",{}).get("conditions",[]) or []
sys.exit(1 if any(x.get("type")=="ComparisonError" for x in c) else 0)' || fail "Application $a reports a ComparisonError"
  [[ "$(app_field "$a" '{.status.sync.status}')" != "Unknown" ]] || fail "Application $a has the sync status Unknown"
done
echo "PASS: None of the three Applications reports a ComparisonError"

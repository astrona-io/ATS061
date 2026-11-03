#!/usr/bin/env bash
# Check: The rendered Deployment git-probe has 3 available replicas
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_until 30 bash -c '[[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath="{.status.availableReplicas}")" == "3" ]]' || fail "Deployment git-probe must have 3 available replicas"
[[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)" == "3" ]] || fail "spec.replicas must be 3"
echo "PASS: The rendered Deployment git-probe has 3 available replicas"

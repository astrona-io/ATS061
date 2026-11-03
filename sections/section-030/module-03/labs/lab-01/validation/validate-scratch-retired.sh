#!/usr/bin/env bash
# Check: The scratch Application and its Deployment gamma are gone
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-030-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
i=0
while kubectl -n argocd get application scratch >/dev/null 2>&1; do
  i=$((i + 1)); [[ $i -gt 30 ]] && fail "Application scratch still exists"
  sleep 3
done
i=0
while kubectl -n starfleet get deployment gamma >/dev/null 2>&1; do
  i=$((i + 1)); [[ $i -gt 30 ]] && fail "Deployment gamma still exists"
  sleep 3
done
echo "PASS: The scratch Application and its Deployment gamma are gone"

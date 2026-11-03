#!/usr/bin/env bash
# Check: Application mission is Synced, Healthy and tracks the git-probe Deployment
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-01-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_until 30 test "$(app_field mission '{.status.sync.status}')" = Synced || fail "Application mission is not Synced"
wait_until 30 test "$(app_field mission '{.status.health.status}')" = Healthy || fail "Application mission is not Healthy"
[[ -n "$(app_field mission '{.status.sync.revision}')" ]] || fail "no resolved commit in status.sync.revision"
track="$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
[[ "$track" == mission:* ]] || fail "Deployment git-probe is not tracked by mission"
echo "PASS: Application mission is Synced, Healthy and tracks the git-probe Deployment"

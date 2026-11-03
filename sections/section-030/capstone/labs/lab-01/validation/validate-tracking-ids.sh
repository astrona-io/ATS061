#!/usr/bin/env bash
# Check: The tracking annotations name probe-chart and fleet as owners
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-030" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
deployment_owner="$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
[[ "$deployment_owner" == probe-chart:apps/Deployment:starfleet/git-probe ]] || fail "Deployment git-probe is not tracked by probe-chart (annotation: '$deployment_owner')"
app_owner="$(kubectl -n argocd get application alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
[[ "$app_owner" == fleet:argoproj.io/Application:argocd/alpha ]] || fail "Application alpha is not tracked by fleet (annotation: '$app_owner')"
echo "PASS: The tracking annotations name probe-chart and fleet as owners"

#!/usr/bin/env bash
# Check: The parent tracks the child Application and the child tracks its Deployment
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-030-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
app_owner="$(kubectl -n argocd get application alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
[[ "$app_owner" == fleet:argoproj.io/Application:argocd/alpha ]] || fail "Application alpha is not tracked by fleet (annotation: '$app_owner')"
deployment_owner="$(kubectl -n starfleet get deployment alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
[[ "$deployment_owner" == alpha:apps/Deployment:starfleet/alpha ]] || fail "Deployment alpha is not tracked by the Application alpha (annotation: '$deployment_owner')"
echo "PASS: The parent tracks the child Application and the child tracks its Deployment"

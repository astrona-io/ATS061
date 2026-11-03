#!/usr/bin/env bash
# Check: Application prod-fleet builds the prod overlay with an inline patch
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field prod-fleet '{.spec.source.path}')" == "kustomize/overlays/prod" ]] || fail "prod-fleet spec.source.path must be kustomize/overlays/prod"
patch="$(app_field prod-fleet '{.spec.source.kustomize.patches[0].patch}')"
[[ "$patch" == *"25m"* && "$patch" == *"git-probe"* ]] || fail "prod-fleet needs an inline patch for git-probe that sets cpu 25m"
echo "PASS: Application prod-fleet builds the prod overlay with an inline patch"

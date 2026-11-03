#!/usr/bin/env bash
# Check: Application mission builds the production overlay
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-02" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field mission '{.spec.source.path}')" == "kustomize/overlays/prod" ]] || fail "spec.source.path must be kustomize/overlays/prod"
[[ "$(app_field mission '{.spec.source.targetRevision}')" == "main" ]] || fail "targetRevision must be main"
[[ "$(app_field mission '{.spec.destination.namespace}')" == "starfleet" ]] || fail "destination namespace must be starfleet"
echo "PASS: Application mission builds the production overlay"

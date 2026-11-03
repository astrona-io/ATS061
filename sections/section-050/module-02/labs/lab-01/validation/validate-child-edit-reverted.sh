#!/usr/bin/env bash
# Check: An edit of a live child Application is reverted by the parent
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application alpha >/dev/null 2>&1 || fail "Application alpha does not exist"
kubectl -n argocd patch application alpha --type merge -p '{"spec":{"source":{"targetRevision":"v1.0.0"}}}' >/dev/null 2>&1 || fail "could not edit alpha"
alpha_is_restored() { test "$(kubectl -n argocd get application alpha -o jsonpath='{.spec.source.targetRevision}')" = main; }
wait_until 30 alpha_is_restored || fail "the parent did not restore the revision of alpha within 90 seconds"
echo "PASS: An edit of a live child Application is reverted by the parent"

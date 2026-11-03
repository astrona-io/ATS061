#!/usr/bin/env bash
# Check: An edit of a generated Application is reverted by the ApplicationSet controller
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-050" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application probe-staging >/dev/null 2>&1 || fail "Application probe-staging does not exist"
kubectl -n argocd patch application probe-staging --type merge -p '{"spec":{"source":{"targetRevision":"v1.0.0"}}}' >/dev/null 2>&1 || fail "could not edit probe-staging"
staging_is_restored() { test "$(kubectl -n argocd get application probe-staging -o jsonpath='{.spec.source.targetRevision}')" = main; }
wait_until 30 staging_is_restored || fail "the ApplicationSet controller did not restore the revision within 90 seconds"
echo "PASS: An edit of a generated Application is reverted by the ApplicationSet controller"

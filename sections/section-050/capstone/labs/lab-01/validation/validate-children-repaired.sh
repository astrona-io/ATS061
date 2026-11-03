#!/usr/bin/env bash
# Check: An edited child is reverted and a deleted child returns without removing its workload
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-050" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
before="$(kubectl -n starfleet get deployment beta -o jsonpath='{.metadata.uid}' 2>/dev/null)"
[[ -n "$before" ]] || fail "Deployment beta does not exist"
kubectl -n argocd patch application alpha --type merge -p '{"spec":{"source":{"targetRevision":"v1.0.0"}}}' >/dev/null 2>&1 || fail "could not edit alpha"
alpha_is_restored() { test "$(kubectl -n argocd get application alpha -o jsonpath='{.spec.source.targetRevision}')" = main; }
wait_until 30 alpha_is_restored || fail "the parent did not restore the revision of alpha within 90 seconds"
old_uid="$(app_field beta '{.metadata.uid}')"
[[ -n "$old_uid" ]] || fail "Application beta does not exist"
kubectl -n argocd delete application beta --wait=true >/dev/null 2>&1 || fail "could not delete beta"
beta_is_new() { local now; now="$(kubectl -n argocd get application beta -o jsonpath='{.metadata.uid}' 2>/dev/null)"; test -n "$now" && test "$now" != "$old_uid"; }
wait_until 30 beta_is_new || fail "the parent did not create Application beta again within 90 seconds"
after="$(kubectl -n starfleet get deployment beta -o jsonpath='{.metadata.uid}' 2>/dev/null)"
[[ "$before" == "$after" ]] || fail "Deployment beta was removed and created again"
echo "PASS: An edited child is reverted and a deleted child returns without removing its workload"

#!/usr/bin/env bash
# Check: Both hooks ran and their Jobs were deleted
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field ordered '{.status.operationState.phase}')" == "Succeeded" ]] || fail "last operation did not succeed"
phases="$(app_field ordered '{range .status.operationState.syncResult.resources[*]}{.syncPhase}{"\n"}{end}')"
grep -qx PreSync <<<"$phases" || fail "no PreSync hook in the sync result"
grep -qx PostSync <<<"$phases" || fail "no PostSync hook in the sync result"
if kubectl -n starfleet get job wave-presync >/dev/null 2>&1 || kubectl -n starfleet get job wave-postsync >/dev/null 2>&1; then
  fail "a hook Job was not deleted after it succeeded"
fi
echo "PASS: Both hooks ran and their Jobs were deleted"

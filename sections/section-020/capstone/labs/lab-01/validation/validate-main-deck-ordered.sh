#!/usr/bin/env bash
# Check: main-deck is synced with options, hooks and no leftover hook Jobs
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-020" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field main-deck '{.spec.source.path}')" == "waves" ]] || fail "path must be waves"
[[ "$(app_field main-deck '{.spec.syncPolicy.automated.prune}')" == "true" ]] || fail "automated prune must be true"
opts="$(app_field main-deck '{.spec.syncPolicy.syncOptions}')"
[[ "$opts" == *CreateNamespace=true* ]] || fail "CreateNamespace=true is missing"
[[ "$opts" == *PruneLast=true* ]] || fail "PruneLast=true is missing"
wait_until 30 test "$(app_field main-deck '{.status.sync.status}')" = Synced || fail "main-deck is not Synced"
wait_until 30 test "$(app_field main-deck '{.status.health.status}')" = Healthy || fail "main-deck is not Healthy"
phases="$(app_field main-deck '{range .status.operationState.syncResult.resources[*]}{.syncPhase}{"\n"}{end}')"
grep -qx PreSync <<<"$phases" || fail "no PreSync hook in the sync result"
grep -qx PostSync <<<"$phases" || fail "no PostSync hook in the sync result"
if kubectl -n starfleet get job wave-presync >/dev/null 2>&1 || kubectl -n starfleet get job wave-postsync >/dev/null 2>&1; then
  fail "a hook Job was not deleted after it succeeded"
fi
echo "PASS: main-deck is synced with options, hooks and no leftover hook Jobs"

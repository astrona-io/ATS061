#!/usr/bin/env bash
# Check: Application ordered has the required source, policy and options
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field ordered '{.spec.source.path}')" == "waves" ]] || fail "path must be waves"
[[ "$(app_field ordered '{.spec.source.targetRevision}')" == "main" ]] || fail "targetRevision must be main"
[[ "$(app_field ordered '{.spec.syncPolicy.automated.prune}')" == "true" ]] || fail "automated prune must be true"
opts="$(app_field ordered '{.spec.syncPolicy.syncOptions}')"
[[ "$opts" == *CreateNamespace=true* ]] || fail "CreateNamespace=true is missing"
[[ "$opts" == *PruneLast=true* ]] || fail "PruneLast=true is missing"
echo "PASS: Application ordered has the required source, policy and options"

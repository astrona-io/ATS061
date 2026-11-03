#!/usr/bin/env bash
# Check: Application frozen has the required source, policy and retry
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field frozen '{.spec.project}')" == "maintenance" ]] || fail "project must be maintenance"
[[ "$(app_field frozen '{.spec.source.path}')" == "workloads/alpha" ]] || fail "path must be workloads/alpha"
[[ "$(app_field frozen '{.spec.source.targetRevision}')" == "main" ]] || fail "targetRevision must be main"
[[ "$(app_field frozen '{.spec.syncPolicy.automated.prune}')" == "true" ]] || fail "automated prune must be true"
[[ "$(app_field frozen '{.spec.syncPolicy.retry.limit}')" == "3" ]] || fail "retry limit must be 3"
[[ "$(app_field frozen '{.spec.syncPolicy.retry.backoff.duration}')" == "10s" ]] || fail "backoff duration must be 10s"
[[ "$(app_field frozen '{.spec.syncPolicy.retry.backoff.factor}')" == "2" ]] || fail "backoff factor must be 2"
[[ "$(app_field frozen '{.spec.syncPolicy.retry.backoff.maxDuration}')" == "2m" ]] || fail "backoff maxDuration must be 2m"
echo "PASS: Application frozen has the required source, policy and retry"

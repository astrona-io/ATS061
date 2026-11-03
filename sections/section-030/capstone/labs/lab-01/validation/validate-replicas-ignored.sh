#!/usr/bin/env bash
# Check: A manual replica change on git-probe is not drift
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-030" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_app() { local app="$1" path="$2" want="$3" i; for ((i = 0; i < 30; i++)); do [[ "$(app_field "$app" "$path")" == "$want" ]] && return 0; sleep 3; done; return 1; }
kubectl -n starfleet get deployment git-probe >/dev/null 2>&1 || fail "Deployment git-probe does not exist"
wait_app probe-chart '{.status.sync.status}' Synced || fail "probe-chart is not Synced"
kubectl -n starfleet scale deployment git-probe --replicas=5 >/dev/null || fail "could not scale the Deployment"
sleep 45
sync_after="$(app_field probe-chart '{.status.sync.status}')"
replicas_after="$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}')"
kubectl -n starfleet scale deployment git-probe --replicas=3 >/dev/null 2>&1
[[ "$sync_after" == "Synced" ]] || fail "probe-chart became OutOfSync after a manual replica change"
[[ "$replicas_after" == "5" ]] || fail "Argo CD changed the replica count back"
echo "PASS: A manual replica change on git-probe is not drift"

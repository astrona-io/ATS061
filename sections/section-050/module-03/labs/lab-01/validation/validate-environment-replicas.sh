#!/usr/bin/env bash
# Check: Each environment has its own namespace and the replica count of its file
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
expect() {
  local env="$1" want="$2" got avail
  got="$(kubectl -n "probe-$env" get deployment git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  [[ "$got" == "$want" ]] || fail "Deployment git-probe in probe-$env has replicas '$got', expected $want"
  avail="$(kubectl -n "probe-$env" get deployment git-probe -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  [[ "$avail" == "$want" ]] || { wait_until 30 test "$(kubectl -n "probe-$env" get deployment git-probe -o jsonpath='{.status.availableReplicas}' 2>/dev/null)" = "$want" || fail "Deployment git-probe in probe-$env has no $want available replicas"; }
}
expect dev 1
expect staging 2
expect prod 3
echo "PASS: Each environment has its own namespace and the replica count of its file"

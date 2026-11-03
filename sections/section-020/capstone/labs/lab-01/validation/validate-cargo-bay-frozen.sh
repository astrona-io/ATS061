#!/usr/bin/env bash
# Check: The deny window blocks cargo-bay
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-020" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
out="$(kubectl -n argocd get appproject freeze -o json 2>/dev/null)" || fail "AppProject freeze not found"
python3 - "$out" <<'PY' || exit 1
import json, sys
p = json.loads(sys.argv[1])
w = p.get("spec", {}).get("syncWindows") or []
if len(w) != 1:
    print("FAIL: the project must have exactly one sync window"); sys.exit(1)
w = w[0]
if w.get("kind") != "deny" or w.get("schedule") != "* * * * *" or w.get("duration") != "24h":
    print("FAIL: the window must be deny, schedule '* * * * *', duration 24h"); sys.exit(1)
if "*" not in (w.get("applications") or []) or w.get("manualSync") is not True:
    print("FAIL: the window must select applications '*' and set manualSync true"); sys.exit(1)
PY
[[ "$(app_field cargo-bay '{.spec.project}')" == "freeze" ]] || fail "cargo-bay must use the project freeze"
[[ "$(app_field cargo-bay '{.spec.source.path}')" == "workloads/beta" ]] || fail "cargo-bay path must be workloads/beta"
[[ "$(app_field cargo-bay '{.spec.syncPolicy.retry.limit}')" == "2" ]] || fail "retry limit must be 2"
[[ -n "$(app_field cargo-bay '{.spec.syncPolicy.automated}')" ]] || fail "cargo-bay must have automated sync"
wait_until 20 test "$(app_field cargo-bay '{.status.sync.status}')" = OutOfSync || fail "cargo-bay is not OutOfSync"
[[ -z "$(app_field cargo-bay '{.status.operationState.phase}')" ]] || fail "a sync operation exists, so the window did not block the sync"
if kubectl -n starfleet get deployment beta >/dev/null 2>&1; then
  fail "Deployment beta exists, so a sync was not blocked"
fi
echo "PASS: The deny window blocks cargo-bay"

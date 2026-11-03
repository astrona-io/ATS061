#!/usr/bin/env bash
# Check: Project maintenance has the always-active deny window
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
out="$(kubectl -n argocd get appproject maintenance -o json 2>/dev/null)" || fail "AppProject maintenance not found"
python3 - "$out" <<'PY' || exit 1
import json, sys
p = json.loads(sys.argv[1])
w = p.get("spec", {}).get("syncWindows") or []
if len(w) != 1:
    print("FAIL: the project must have exactly one sync window"); sys.exit(1)
w = w[0]
if w.get("kind") != "deny":
    print("FAIL: the window kind must be deny"); sys.exit(1)
if w.get("schedule") != "* * * * *" or w.get("duration") != "24h":
    print("FAIL: schedule must be '* * * * *' and duration 24h"); sys.exit(1)
if "*" not in (w.get("applications") or []):
    print("FAIL: the window must select applications '*'"); sys.exit(1)
if w.get("manualSync") is not True:
    print("FAIL: manualSync must be true"); sys.exit(1)
print("PASS: deny window is configured")
PY
echo "PASS: Project maintenance has the always-active deny window"

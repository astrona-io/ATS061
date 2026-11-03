#!/usr/bin/env bash
# Check: release-train was synced twice and rolled back to the first revision
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-020-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field release-train '{.spec.source.path}')" == "plain" ]] || fail "path must be plain"
[[ -z "$(app_field release-train '{.spec.syncPolicy.automated}')" ]] || fail "automated sync must be off"
out="$(kubectl -n argocd get application release-train -o json 2>/dev/null)" || fail "Application release-train not found"
python3 - "$out" <<'PY' || exit 1
import json, sys
a = json.loads(sys.argv[1])
h = a.get("status", {}).get("history") or []
revs = [e.get("revision") for e in h]
if len(revs) < 3:
    print("FAIL: history needs at least three entries (main, release, rollback)"); sys.exit(1)
if len(set(revs)) < 2:
    print("FAIL: history must hold two different revisions"); sys.exit(1)
if revs[-1] != revs[0]:
    print("FAIL: the latest history entry must have the revision of the first one"); sys.exit(1)
print("PASS: history shows a rollback")
PY
[[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)" == "2" ]] || fail "Deployment git-probe must have 2 replicas"
echo "PASS: release-train was synced twice and rolled back to the first revision"

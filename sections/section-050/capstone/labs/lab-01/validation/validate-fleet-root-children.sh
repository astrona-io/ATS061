#!/usr/bin/env bash
# Check: fleet-root creates and owns alpha and beta and both are Synced and Healthy
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-050" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
out="$(kubectl -n argocd get application fleet-root -o json 2>/dev/null)" || fail "Application fleet-root not found"
python3 - "$out" <<'PY' || exit 1
import json, sys
a = json.loads(sys.argv[1])["spec"]
def bad(m):
    print("FAIL: " + m); sys.exit(1)
if a.get("source", {}).get("path") != "apps" or a.get("source", {}).get("targetRevision") != "main":
    bad("fleet-root must read path apps on revision main")
if a.get("destination", {}).get("namespace") != "argocd":
    bad("the destination namespace of fleet-root must be argocd")
auto = (a.get("syncPolicy") or {}).get("automated") or {}
if auto.get("prune") is not True or auto.get("selfHeal") is not True:
    bad("fleet-root needs automated sync with prune and selfHeal")
PY
for child in alpha beta; do
  wait_until 30 kubectl -n argocd get application "$child" || fail "Application $child does not exist"
  track="$(app_field "$child" '{.metadata.annotations.argocd\.argoproj\.io/tracking-id}')"
  [[ "$track" == fleet-root:* ]] || fail "Application $child is not owned by fleet-root"
  wait_until 40 test "$(app_field "$child" '{.status.sync.status}')" = Synced || fail "Application $child is not Synced"
  wait_until 40 test "$(app_field "$child" '{.status.health.status}')" = Healthy || fail "Application $child is not Healthy"
done
echo "PASS: fleet-root creates and owns alpha and beta and both are Synced and Healthy"

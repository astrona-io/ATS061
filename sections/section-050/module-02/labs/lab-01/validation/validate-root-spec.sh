#!/usr/bin/env bash
# Check: Application fleet-root reads the apps path with automated prune and self-heal
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-02-01" ]]; then
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
s = a.get("source", {})
if s.get("path") != "apps" or s.get("targetRevision") != "main":
    bad("source must be path apps on revision main")
if a.get("project") != "default":
    bad("project must be default")
d = a.get("destination", {})
if d.get("namespace") != "argocd" or d.get("server") != "https://kubernetes.default.svc":
    bad("destination must be https://kubernetes.default.svc and namespace argocd")
auto = (a.get("syncPolicy") or {}).get("automated") or {}
if auto.get("prune") is not True or auto.get("selfHeal") is not True:
    bad("automated sync needs prune and selfHeal set to true")
PY
echo "PASS: Application fleet-root reads the apps path with automated prune and self-heal"

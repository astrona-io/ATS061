#!/usr/bin/env bash
# Check: Application ops-bridge ignores only the replica count and respects it during sync
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-050" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
out="$(kubectl -n argocd get application ops-bridge -o json 2>/dev/null)" || fail "Application ops-bridge not found"
python3 - "$out" <<'PY' || exit 1
import json, sys
a = json.loads(sys.argv[1])["spec"]
def bad(m):
    print("FAIL: " + m); sys.exit(1)
s = a.get("source", {})
if s.get("path") != "plain" or s.get("targetRevision") != "main":
    bad("source must be path plain on revision main")
if a.get("destination", {}).get("namespace") != "starfleet":
    bad("destination namespace must be starfleet")
p = a.get("syncPolicy", {})
auto = p.get("automated") or {}
if auto.get("prune") is not True or auto.get("selfHeal") is not True:
    bad("automated sync needs prune and selfHeal set to true")
if "RespectIgnoreDifferences=true" not in (p.get("syncOptions") or []):
    bad("sync option RespectIgnoreDifferences=true is missing")
r = a.get("ignoreDifferences") or []
if len(r) != 1 or r[0].get("group") != "apps" or r[0].get("kind") != "Deployment" or r[0].get("jsonPointers") != ["/spec/replicas"] or r[0].get("jqPathExpressions") or r[0].get("managedFieldsManagers"):
    bad("exactly one rule for apps Deployment with only the pointer /spec/replicas is required")
PY
echo "PASS: Application ops-bridge ignores only the replica count and respects it during sync"

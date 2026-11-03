#!/usr/bin/env bash
# Check: Application mission has the required policy and one narrow ignore rule
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-01-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
out="$(kubectl -n argocd get application mission -o json 2>/dev/null)" || fail "Application mission not found"
python3 - "$out" <<'PY' || exit 1
import json, sys
a = json.loads(sys.argv[1])["spec"]
def bad(msg):
    print("FAIL: " + msg); sys.exit(1)
src = a.get("source", {})
if src.get("path") != "plain" or src.get("targetRevision") != "main":
    bad("source must be path plain on revision main")
if a.get("project") != "default":
    bad("project must be default")
if a.get("destination", {}).get("namespace") != "starfleet":
    bad("destination namespace must be starfleet")
pol = a.get("syncPolicy", {})
auto = pol.get("automated") or {}
if auto.get("prune") is not True or auto.get("selfHeal") is not True:
    bad("automated sync needs prune and selfHeal set to true")
if "RespectIgnoreDifferences=true" not in (pol.get("syncOptions") or []):
    bad("sync option RespectIgnoreDifferences=true is missing")
rules = a.get("ignoreDifferences") or []
if len(rules) != 1:
    bad("exactly one ignoreDifferences entry is required")
r = rules[0]
if r.get("group") != "apps" or r.get("kind") != "Deployment":
    bad("the rule must select group apps and kind Deployment")
if r.get("jsonPointers") != ["/spec/replicas"] or r.get("jqPathExpressions") or r.get("managedFieldsManagers"):
    bad("the rule must ignore only the pointer /spec/replicas")
PY
echo "PASS: Application mission has the required policy and one narrow ignore rule"

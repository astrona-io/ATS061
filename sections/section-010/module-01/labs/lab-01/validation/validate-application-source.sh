#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-01-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-01-01" >&2
  exit 1
fi
app_json="$(kubectl -n argocd get application mission -o json 2>/dev/null)" || { echo "FAIL: Application mission not found in namespace argocd"; exit 1; }
result="$(printf '%s' "$app_json" | python3 -c '
import json,sys
a=json.load(sys.stdin)["spec"]
s=a["source"]; d=a["destination"]
print(a.get("project",""),s.get("repoURL",""),s.get("targetRevision",""),s.get("path",""),d.get("namespace",""))')"
expected="default http://git-source.argocd.svc:8080/repo.git main plain starfleet"
if [[ "$result" == "$expected" ]]; then
  echo "PASS: mission reads plain from main and targets starfleet"
else
  echo "FAIL: mission source is '$result', expected '$expected'"
  exit 1
fi

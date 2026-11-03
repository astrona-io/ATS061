#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-02-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-02-01" >&2
  exit 1
fi
app_json="$(kubectl -n argocd get application fleet-registry -o json 2>/dev/null)" || { echo "FAIL: Application fleet-registry not found in namespace argocd"; exit 1; }
result="$(printf '%s' "$app_json" | python3 -c '
import json,sys
s=json.load(sys.stdin)["spec"]["source"]
print(s.get("path",""),s.get("targetRevision",""))')"
if [[ "$result" == "plain v1.0.0" ]]; then
  echo "PASS: fleet-registry reads path plain at revision v1.0.0"
else
  echo "FAIL: fleet-registry source is '$result' (expected path plain, revision v1.0.0)"
  exit 1
fi

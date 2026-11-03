#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-capstone-010" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-capstone-010" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  result="$(kubectl -n argocd get application flight-deck -o json 2>/dev/null | python3 -c '
import json,sys
a=json.load(sys.stdin); s=a.get("status",{})
errs=[c for c in s.get("conditions",[]) if c.get("type")=="ComparisonError"]
p=s.get("sync",{}).get("comparedTo",{}).get("source",{}).get("path","")
ok=p=="plain" and s.get("sync",{}).get("status")=="Synced" and s.get("health",{}).get("status")=="Healthy" and not errs
print("ok" if ok else "no")' 2>/dev/null)"
  available="$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [[ "$result" == "ok" && "$available" == "2" ]]; then
    echo "PASS: flight-deck compares plain, is Synced and Healthy and git-probe has 2 available replicas"
    exit 0
  fi
  sleep 5
done
echo "FAIL: flight-deck is not repaired (result ${result:-none}, git-probe available ${available:-0})"
exit 1

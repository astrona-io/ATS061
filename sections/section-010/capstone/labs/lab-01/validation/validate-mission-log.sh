#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-capstone-010" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-capstone-010" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  result="$(kubectl -n argocd get application mission-log -o json 2>/dev/null | python3 -c '
import json,sys
a=json.load(sys.stdin); s=a.get("status",{}); sp=a.get("spec",{})
auto=sp.get("syncPolicy",{}).get("automated") or {}
ok=(s.get("sync",{}).get("comparedTo",{}).get("source",{}).get("path")=="workloads/gamma"
    and s.get("sync",{}).get("status")=="Synced" and s.get("health",{}).get("status")=="Healthy"
    and auto.get("selfHeal") is True and auto.get("prune") is True)
print("ok" if ok else "no")' 2>/dev/null)"
  tracked="$(kubectl -n starfleet get deployment gamma -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null)"
  available="$(kubectl -n starfleet get deployment gamma -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
  if [[ "$result" == "ok" && "$tracked" == mission-log:* && "$available" == "1" ]]; then
    echo "PASS: mission-log delivers gamma with automated prune and self-healing, Synced and Healthy"
    exit 0
  fi
  sleep 5
done
echo "FAIL: mission-log not correct (result ${result:-none}, tracking '${tracked:-none}', available ${available:-0})"
exit 1

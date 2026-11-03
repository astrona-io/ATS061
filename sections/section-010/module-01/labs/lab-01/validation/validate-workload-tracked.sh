#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-01-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-01-01" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  result="$(kubectl -n starfleet get deployment git-probe -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
t=d["metadata"].get("annotations",{}).get("argocd.argoproj.io/tracking-id","")
a=d.get("status",{}).get("availableReplicas",0)
print("ok" if a==2 and t.startswith("mission:") else "no")' 2>/dev/null)"
  if [[ "$result" == "ok" ]]; then
    echo "PASS: git-probe has 2 available replicas and is tracked by mission"
    exit 0
  fi
  sleep 5
done
echo "FAIL: git-probe is missing, not at 2 available replicas, or not tracked by mission"
exit 1

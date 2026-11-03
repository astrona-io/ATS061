#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-03-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-03-01" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  result="$(kubectl -n starfleet get deployment beta -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
t=d["metadata"].get("annotations",{}).get("argocd.argoproj.io/tracking-id","")
a=d.get("status",{}).get("availableReplicas",0)
print("ok" if a==1 and t.startswith("bridge-cam:") else "no")' 2>/dev/null)"
  if [[ "$result" == "ok" ]]; then
    echo "PASS: Deployment beta has 1 available replica and is tracked by bridge-cam"
    exit 0
  fi
  sleep 5
done
echo "FAIL: Deployment beta is missing, not available or not tracked by bridge-cam"
exit 1

#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-02-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-02-01" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  sync_status="$(kubectl -n argocd get application fleet-registry -o jsonpath='{.status.sync.status}' 2>/dev/null)"
  error_count="$(kubectl -n argocd get application fleet-registry -o json 2>/dev/null | python3 -c '
import json,sys
c=json.load(sys.stdin).get("status",{}).get("conditions",[])
print(sum(1 for x in c if x.get("type")=="ComparisonError"))' 2>/dev/null)"
  if [[ "$sync_status" == "Synced" && "$error_count" == "0" ]]; then
    echo "PASS: fleet-registry is Synced and has no ComparisonError condition"
    exit 0
  fi
  sleep 5
done
echo "FAIL: fleet-registry sync status is '${sync_status:-empty}' with $error_count ComparisonError condition(s)"
exit 1

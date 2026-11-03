#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-01-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-01-01" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  sync_status="$(kubectl -n argocd get application mission -o jsonpath='{.status.sync.status}' 2>/dev/null)"
  health="$(kubectl -n argocd get application mission -o jsonpath='{.status.health.status}' 2>/dev/null)"
  revision="$(kubectl -n argocd get application mission -o jsonpath='{.status.sync.revision}' 2>/dev/null)"
  if [[ "$sync_status" == "Synced" && "$health" == "Healthy" && "$revision" =~ ^[0-9a-f]{40}$ ]]; then
    echo "PASS: mission is Synced and Healthy at revision $revision"
    exit 0
  fi
  sleep 5
done
echo "FAIL: mission sync '${sync_status:-empty}', health '${health:-empty}', revision '${revision:-empty}'"
exit 1

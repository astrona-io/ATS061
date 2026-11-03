#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-03-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-03-01" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  sync_status="$(kubectl -n argocd get application bridge-cam -o jsonpath='{.status.sync.status}' 2>/dev/null)"
  health="$(kubectl -n argocd get application bridge-cam -o jsonpath='{.status.health.status}' 2>/dev/null)"
  if [[ "$sync_status" == "Synced" && "$health" == "Healthy" ]]; then
    echo "PASS: bridge-cam is Synced and Healthy"
    exit 0
  fi
  sleep 5
done
echo "FAIL: bridge-cam is sync ${sync_status:-empty} and health ${health:-empty}"
exit 1

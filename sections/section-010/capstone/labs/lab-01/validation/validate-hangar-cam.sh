#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-capstone-010" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-capstone-010" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  path="$(kubectl -n argocd get application hangar-cam -o jsonpath='{.status.sync.comparedTo.source.path}' 2>/dev/null)"
  sync_status="$(kubectl -n argocd get application hangar-cam -o jsonpath='{.status.sync.status}' 2>/dev/null)"
  health="$(kubectl -n argocd get application hangar-cam -o jsonpath='{.status.health.status}' 2>/dev/null)"
  if ! kubectl -n starfleet get deployment bad-image >/dev/null 2>&1 \
     && [[ "$path" == "workloads/beta" && "$sync_status" == "Synced" && "$health" == "Healthy" ]]; then
    echo "PASS: hangar-cam compares workloads/beta, is Synced and Healthy and bad-image is gone"
    exit 0
  fi
  sleep 5
done
echo "FAIL: hangar-cam path '${path:-none}', sync '${sync_status:-none}', health '${health:-none}', or bad-image still exists"
exit 1

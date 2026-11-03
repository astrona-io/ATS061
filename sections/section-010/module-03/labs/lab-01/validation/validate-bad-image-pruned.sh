#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-03-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-03-01" >&2
  exit 1
fi
for attempt in $(seq 1 18); do
  if ! kubectl -n starfleet get deployment bad-image >/dev/null 2>&1; then
    echo "PASS: Deployment bad-image no longer exists"
    exit 0
  fi
  sleep 5
done
echo "FAIL: Deployment bad-image still exists in starfleet"
exit 1

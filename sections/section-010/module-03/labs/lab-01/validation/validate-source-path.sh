#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-03-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-03-01" >&2
  exit 1
fi
path="$(kubectl -n argocd get application bridge-cam -o jsonpath='{.status.sync.comparedTo.source.path}' 2>/dev/null)"
if [[ "$path" == "workloads/beta" ]]; then
  echo "PASS: bridge-cam compares the directory workloads/beta"
else
  echo "FAIL: bridge-cam compares '${path:-nothing}', expected workloads/beta"
  exit 1
fi

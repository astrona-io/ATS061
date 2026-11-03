#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-02-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-02-01" >&2
  exit 1
fi
revision="$(kubectl -n argocd get application fleet-registry -o jsonpath='{.status.sync.revision}' 2>/dev/null)"
if [[ "$revision" =~ ^[0-9a-f]{40}$ ]]; then
  echo "PASS: fleet-registry resolved revision $revision"
else
  echo "FAIL: status.sync.revision is '${revision:-empty}', not a 40 character commit"
  exit 1
fi

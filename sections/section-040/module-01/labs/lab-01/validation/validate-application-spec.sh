#!/usr/bin/env bash
# Check: Application mission renders the chart with the production values file
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field mission '{.spec.source.path}')" == "chart" ]] || fail "spec.source.path must be chart"
[[ "$(app_field mission '{.spec.source.targetRevision}')" == "main" ]] || fail "targetRevision must be main"
[[ "$(app_field mission '{.spec.source.helm.valueFiles[0]}')" == "values-prod.yaml" ]] || fail "spec.source.helm.valueFiles must hold values-prod.yaml"
[[ "$(app_field mission '{.spec.destination.namespace}')" == "starfleet" ]] || fail "destination namespace must be starfleet"
echo "PASS: Application mission renders the chart with the production values file"

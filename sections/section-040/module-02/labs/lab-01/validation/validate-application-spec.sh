#!/usr/bin/env bash
# Check: Application fleet-chart layers a values file, a values object and a parameter
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field fleet-chart '{.spec.source.path}')" == "chart" ]] || fail "spec.source.path must be chart"
[[ "$(app_field fleet-chart '{.spec.source.targetRevision}')" == "main" ]] || fail "targetRevision must be main"
[[ "$(app_field fleet-chart '{.spec.source.helm.valueFiles[0]}')" == "values-prod.yaml" ]] || fail "valueFiles must hold values-prod.yaml"
[[ "$(app_field fleet-chart '{.spec.source.helm.valuesObject.image.tag}')" == "3.12-alpine" ]] || fail "valuesObject must set image.tag to 3.12-alpine"
[[ "$(app_field fleet-chart '{.spec.source.helm.parameters[?(@.name=="replicas")].value}')" == "4" ]] || fail "a parameter named replicas with the value 4 is required"
[[ "$(app_field fleet-chart '{.spec.destination.namespace}')" == "outpost" ]] || fail "destination namespace must be outpost"
echo "PASS: Application fleet-chart layers a values file, a values object and a parameter"

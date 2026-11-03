#!/usr/bin/env bash
# Check: fleet-chart renders without error with the production values layered
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-040" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application fleet-chart >/dev/null 2>&1 || fail "Application fleet-chart not found"
[[ "$(app_field fleet-chart '{.spec.source.helm.valueFiles[0]}')" == "values-prod.yaml" ]] || fail "valueFiles must hold values-prod.yaml"
[[ "$(app_field fleet-chart '{.spec.source.helm.valuesObject.image.tag}')" == "3.12-alpine" ]] || fail "valuesObject must set image.tag to 3.12-alpine"
[[ "$(app_field fleet-chart '{.spec.source.helm.parameters[?(@.name=="replicas")].value}')" == "4" ]] || fail "a parameter named replicas with the value 4 is required"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/fleet-chart --timeout=90s >/dev/null 2>&1 || fail "fleet-chart is not Synced"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/fleet-chart --timeout=90s >/dev/null 2>&1 || fail "fleet-chart is not Healthy"
wait_until 30 bash -c '[[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath="{.status.availableReplicas}")" == "4" ]]' || fail "Deployment git-probe must have 4 available replicas"
img="$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
[[ "$img" == "docker.io/library/python:3.12-alpine" ]] || fail "git-probe image must be docker.io/library/python:3.12-alpine, found '$img'"
echo "PASS: fleet-chart renders without error with the production values layered"

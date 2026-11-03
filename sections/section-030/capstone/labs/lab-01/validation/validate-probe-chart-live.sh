#!/usr/bin/env bash
# Check: probe-chart renders the chart with the production values and the image parameter
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-030" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_app() { local app="$1" path="$2" want="$3" i; for ((i = 0; i < 30; i++)); do [[ "$(app_field "$app" "$path")" == "$want" ]] && return 0; sleep 3; done; return 1; }
[[ "$(app_field probe-chart '{.spec.project}')" == "bridge" ]] || fail "probe-chart must use the project bridge"
[[ "$(app_field probe-chart '{.spec.source.path}')" == "chart" ]] || fail "path must be chart"
[[ "$(app_field probe-chart '{.spec.source.helm.valueFiles[0]}')" == "values-prod.yaml" ]] || fail "valueFiles must hold values-prod.yaml"
[[ "$(app_field probe-chart '{.spec.source.helm.parameters[?(@.name==\"image.tag\")].value}')" == "3.12-alpine" ]] || fail "parameter image.tag must be 3.12-alpine"
[[ -z "$(app_field probe-chart '{.spec.source.helm.valuesObject}')" ]] || fail "do not set valuesObject"
[[ "$(app_field probe-chart '{.spec.syncPolicy.automated.selfHeal}')" == "true" ]] || fail "automated selfHeal must be true"
[[ "$(app_field probe-chart '{.metadata.finalizers}')" == *resources-finalizer.argocd.argoproj.io* ]] || fail "probe-chart needs the finalizer resources-finalizer.argocd.argoproj.io"
wait_app probe-chart '{.status.sync.status}' Synced || fail "probe-chart is not Synced"
wait_app probe-chart '{.status.health.status}' Healthy || fail "probe-chart is not Healthy"
[[ -z "$(app_field probe-chart '{.status.conditions}')" ]] || fail "probe-chart reports conditions: $(app_field probe-chart '{.status.conditions[*].message}')"
[[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)" == "3" ]] || fail "Deployment git-probe must have 3 replicas"
[[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)" == "docker.io/library/python:3.12-alpine" ]] || fail "Deployment git-probe must use python:3.12-alpine"
echo "PASS: probe-chart renders the chart with the production values and the image parameter"

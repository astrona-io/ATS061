#!/usr/bin/env bash
# Check: Deployment prod-git-probe has 3 available replicas, the production label and the pinned image
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-02" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_until 30 bash -c '[[ "$(kubectl -n starfleet get deployment prod-git-probe -o jsonpath="{.status.availableReplicas}")" == "3" ]]' || fail "Deployment prod-git-probe must have 3 available replicas"
[[ "$(kubectl -n starfleet get deployment prod-git-probe -o jsonpath='{.metadata.labels.environment}' 2>/dev/null)" == "prod" ]] || fail "label environment=prod missing"
img="$(kubectl -n starfleet get deployment prod-git-probe -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
[[ "$img" == "docker.io/library/python:3.12-alpine" ]] || fail "image must be docker.io/library/python:3.12-alpine, found '$img'"
echo "PASS: Deployment prod-git-probe has 3 available replicas, the production label and the pinned image"

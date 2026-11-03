#!/usr/bin/env bash
# Check: The Deployment uses the chart default image
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
img="$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
[[ "$img" == "docker.io/library/python:3.13-alpine" ]] || fail "image must be docker.io/library/python:3.13-alpine, found '$img'"
echo "PASS: The Deployment uses the chart default image"

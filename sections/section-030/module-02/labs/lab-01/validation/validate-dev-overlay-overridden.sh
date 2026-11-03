#!/usr/bin/env bash
# Check: probe-dev renders the dev overlay with the image override
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-030-02-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_app() { local app="$1" path="$2" want="$3" i; for ((i = 0; i < 30; i++)); do [[ "$(app_field "$app" "$path")" == "$want" ]] && return 0; sleep 3; done; return 1; }
[[ "$(app_field probe-dev '{.status.sourceType}')" == "Kustomize" ]] || fail "probe-dev must be a Kustomize source"
[[ "$(app_field probe-dev '{.spec.source.path}')" == "kustomize/overlays/dev" ]] || fail "path must be kustomize/overlays/dev"
[[ "$(app_field probe-dev '{.spec.source.kustomize.images[0]}')" == "docker.io/library/python:3.12-alpine" ]] || fail "kustomize images must hold docker.io/library/python:3.12-alpine"
[[ -n "$(app_field probe-dev '{.spec.syncPolicy.automated}')" ]] || fail "probe-dev needs an automated sync policy"
wait_app probe-dev '{.status.sync.status}' Synced || fail "probe-dev is not Synced"
wait_app probe-dev '{.status.health.status}' Healthy || fail "probe-dev is not Healthy"
[[ "$(kubectl -n starfleet get deployment dev-git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)" == "1" ]] || fail "Deployment dev-git-probe must have 1 replica"
[[ "$(kubectl -n starfleet get deployment dev-git-probe -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)" == "docker.io/library/python:3.12-alpine" ]] || fail "Deployment dev-git-probe must use python:3.12-alpine"
echo "PASS: probe-dev renders the dev overlay with the image override"

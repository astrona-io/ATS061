#!/usr/bin/env bash
# Check: bridge-dev builds the dev overlay with the image override and runs live
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-040" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application bridge-dev >/dev/null 2>&1 || fail "Application bridge-dev not found"
[[ "$(app_field bridge-dev '{.spec.source.path}')" == "kustomize/overlays/dev" ]] || fail "bridge-dev path must be kustomize/overlays/dev"
[[ "$(app_field bridge-dev '{.spec.source.kustomize.images[0]}')" == "docker.io/library/python:3.12-alpine" ]] || fail "bridge-dev must override the image with docker.io/library/python:3.12-alpine"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/bridge-dev --timeout=90s >/dev/null 2>&1 || fail "bridge-dev is not Synced"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/bridge-dev --timeout=90s >/dev/null 2>&1 || fail "bridge-dev is not Healthy"
[[ "$(app_field bridge-dev '{.status.sourceType}')" == "Kustomize" ]] || fail "bridge-dev sourceType must be Kustomize"
[[ "$(kubectl -n starfleet get deployment dev-git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}' 2>/dev/null)" == "1 docker.io/library/python:3.12-alpine" ]] || fail "dev-git-probe must have 1 replica and the tag 3.12-alpine"
echo "PASS: bridge-dev builds the dev overlay with the image override and runs live"

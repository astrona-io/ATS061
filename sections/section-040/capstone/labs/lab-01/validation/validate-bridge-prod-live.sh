#!/usr/bin/env bash
# Check: bridge-prod builds the prod overlay with two replicas set in the Application
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-040" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application bridge-prod >/dev/null 2>&1 || fail "Application bridge-prod not found"
[[ "$(app_field bridge-prod '{.spec.source.path}')" == "kustomize/overlays/prod" ]] || fail "bridge-prod path must be kustomize/overlays/prod"
[[ "$(app_field bridge-prod '{.spec.source.kustomize.replicas[0].name}')" == "git-probe" ]] || fail "kustomize.replicas must name the base Deployment git-probe"
[[ "$(app_field bridge-prod '{.spec.source.kustomize.replicas[0].count}')" == "2" ]] || fail "kustomize.replicas count must be 2"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/bridge-prod --timeout=90s >/dev/null 2>&1 || fail "bridge-prod is not Synced"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/bridge-prod --timeout=90s >/dev/null 2>&1 || fail "bridge-prod is not Healthy"
wait_until 30 bash -c '[[ "$(kubectl -n starfleet get deployment prod-git-probe -o jsonpath="{.status.availableReplicas}")" == "2" ]]' || fail "prod-git-probe must have 2 available replicas"
kubectl -n starfleet get deployment prod-git-probe -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | grep -q ':3.12-alpine$' || fail "prod-git-probe must keep the overlay tag 3.12-alpine"
echo "PASS: bridge-prod builds the prod overlay with two replicas set in the Application"

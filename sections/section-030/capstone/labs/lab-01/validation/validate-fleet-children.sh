#!/usr/bin/env bash
# Check: fleet is an automated app of apps and its children are Synced and Healthy
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-030" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
wait_app() { local app="$1" path="$2" want="$3" i; for ((i = 0; i < 30; i++)); do [[ "$(app_field "$app" "$path")" == "$want" ]] && return 0; sleep 3; done; return 1; }
[[ "$(app_field fleet '{.spec.project}')" == "default" ]] || fail "fleet must use the project default"
[[ "$(app_field fleet '{.spec.source.path}')" == "apps" ]] || fail "fleet must use the path apps"
[[ "$(app_field fleet '{.spec.destination.namespace}')" == "argocd" ]] || fail "fleet must deploy to the namespace argocd"
[[ "$(app_field fleet '{.spec.syncPolicy.automated.prune}')" == "true" ]] || fail "automated prune must be true"
[[ "$(app_field fleet '{.spec.syncPolicy.automated.selfHeal}')" == "true" ]] || fail "automated selfHeal must be true"
[[ "$(app_field fleet '{.metadata.finalizers}')" == *resources-finalizer.argocd.argoproj.io* ]] || fail "fleet needs the finalizer resources-finalizer.argocd.argoproj.io"
wait_app fleet '{.status.sync.status}' Synced || fail "fleet is not Synced"
for child in alpha beta; do
  wait_app "$child" '{.status.sync.status}' Synced || fail "Application $child is not Synced"
  wait_app "$child" '{.status.health.status}' Healthy || fail "Application $child is not Healthy"
  kubectl -n starfleet get deployment "$child" >/dev/null 2>&1 || fail "Deployment $child does not exist"
done
echo "PASS: fleet is an automated app of apps and its children are Synced and Healthy"

#!/usr/bin/env bash
# Check: The three generated Applications are owned by the ApplicationSet and Synced and Healthy
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
for env in dev staging prod; do
  wait_until 30 kubectl -n argocd get application "probe-$env" || fail "Application probe-$env does not exist"
  owner="$(app_field "probe-$env" '{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}')"
  [[ "$owner" == "ApplicationSet/fleet-envs" ]] || fail "Application probe-$env is not owned by the ApplicationSet fleet-envs"
  [[ "$(app_field "probe-$env" '{.spec.source.path}')" == "kustomize/base" ]] || fail "probe-$env must deploy kustomize/base"
  [[ "$(app_field "probe-$env" '{.spec.syncPolicy.automated.selfHeal}')" == "true" ]] || fail "probe-$env needs automated sync with selfHeal"
  wait_until 40 test "$(app_field "probe-$env" '{.status.sync.status}')" = Synced || fail "Application probe-$env is not Synced"
  wait_until 40 test "$(app_field "probe-$env" '{.status.health.status}')" = Healthy || fail "Application probe-$env is not Healthy"
done
echo "PASS: The three generated Applications are owned by the ApplicationSet and Synced and Healthy"

#!/usr/bin/env bash
# Check: fleet-envs generates three owned Applications with the replica counts of the data files
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-050" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
out="$(kubectl -n argocd get applicationset fleet-envs -o json 2>/dev/null)" || fail "ApplicationSet fleet-envs not found"
python3 - "$out" <<'PY' || exit 1
import json, sys
a = json.loads(sys.argv[1])["spec"]
def bad(m):
    print("FAIL: " + m); sys.exit(1)
gens = a.get("generators") or []
if len(gens) != 1 or "git" not in gens[0]:
    bad("exactly one git generator is required")
if [f.get("path") for f in gens[0]["git"].get("files") or []] != ["envs/*/config.json"]:
    bad("the generator must use the files path envs/*/config.json")
if "{{" not in a.get("template", {}).get("metadata", {}).get("name", ""):
    bad("the Application name in the template must use a parameter")
PY
want_dev=1; want_staging=2; want_prod=3
for env in dev staging prod; do
  wait_until 30 kubectl -n argocd get application "probe-$env" || fail "Application probe-$env does not exist"
  owner="$(app_field "probe-$env" '{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}')"
  [[ "$owner" == "ApplicationSet/fleet-envs" ]] || fail "Application probe-$env is not owned by the ApplicationSet fleet-envs"
  wait_until 40 test "$(app_field "probe-$env" '{.status.sync.status}')" = Synced || fail "Application probe-$env is not Synced"
  wait_until 40 test "$(app_field "probe-$env" '{.status.health.status}')" = Healthy || fail "Application probe-$env is not Healthy"
  var="want_$env"; want="${!var}"
  [[ "$(kubectl -n "probe-$env" get deployment git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)" == "$want" ]] || fail "Deployment git-probe in probe-$env does not have $want replicas"
done
echo "PASS: fleet-envs generates three owned Applications with the replica counts of the data files"

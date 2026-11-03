#!/usr/bin/env bash
# Check: AppProject bridge allows one repository, one destination and only Deployment and Service
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-capstone-030" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
project_json="$(kubectl -n argocd get appproject bridge -o json 2>/dev/null)" || fail "AppProject bridge does not exist"
PROJECT_JSON="$project_json" python3 -c '
import json, os, sys
spec = json.loads(os.environ["PROJECT_JSON"])["spec"]
def fail(m):
    print("FAIL: " + m); sys.exit(1)
if spec.get("sourceRepos") != ["http://git-source.argocd.svc:8080/repo.git"]:
    fail("sourceRepos must hold only the Git server URL")
d = spec.get("destinations") or []
if len(d) != 1 or d[0].get("server") != "https://kubernetes.default.svc" or d[0].get("namespace") != "starfleet":
    fail("destinations must hold only the in-cluster server and the namespace starfleet")
w = {(x.get("group", ""), x.get("kind")) for x in spec.get("namespaceResourceWhitelist") or []}
if w != {("apps", "Deployment"), ("", "Service")}:
    fail("namespaceResourceWhitelist must allow only apps/Deployment and Service")
' || exit 1
echo "PASS: AppProject bridge allows one repository, one destination and only Deployment and Service"

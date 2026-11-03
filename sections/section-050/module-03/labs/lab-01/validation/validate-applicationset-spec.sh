#!/usr/bin/env bash
# Check: ApplicationSet fleet-envs reads envs/*/config.json with a Git files generator
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-03-01" ]]; then
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
g = gens[0]["git"]
if g.get("repoURL") != "http://git-source.argocd.svc:8080/repo.git" or g.get("revision") != "main":
    bad("the generator must read the repository on revision main")
if [f.get("path") for f in g.get("files") or []] != ["envs/*/config.json"]:
    bad("the generator must use the files path envs/*/config.json")
t = a.get("template", {})
if "{{" not in t.get("metadata", {}).get("name", ""):
    bad("the Application name in the template must use a parameter")
if t.get("spec", {}).get("source", {}).get("path") != "kustomize/base":
    bad("the template must deploy the path kustomize/base")
PY
echo "PASS: ApplicationSet fleet-envs reads envs/*/config.json with a Git files generator"

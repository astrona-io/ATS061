#!/usr/bin/env bash
# Check: dev-fleet is Synced and Healthy and the live dev objects carry the overrides
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application dev-fleet >/dev/null 2>&1 || fail "Application dev-fleet not found"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/dev-fleet --timeout=90s >/dev/null 2>&1 || fail "dev-fleet is not Synced"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/dev-fleet --timeout=90s >/dev/null 2>&1 || fail "dev-fleet is not Healthy"
[[ "$(app_field dev-fleet '{.status.sourceType}')" == "Kustomize" ]] || fail "dev-fleet sourceType must be Kustomize"
kubectl -n starfleet get deployment dev-git-probe -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
img=d["spec"]["template"]["spec"]["containers"][0]["image"]
ann=d["metadata"].get("annotations",{}).get("fleet.starfleet/owner")
ok=d["spec"]["replicas"]==1 and img=="docker.io/library/python:3.12-alpine" and ann=="operations"
print(("" if ok else "bad ")+str(d["spec"]["replicas"])+" "+img+" "+str(ann))
sys.exit(0 if ok else 1)' >/dev/null || fail "dev-git-probe must have 1 replica, tag 3.12-alpine and the owner annotation"
echo "PASS: dev-fleet is Synced and Healthy and the live dev objects carry the overrides"

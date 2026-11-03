#!/usr/bin/env bash
# Check: prod-fleet is Synced and Healthy and the live Deployment has the patched resource request
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n argocd get application prod-fleet >/dev/null 2>&1 || fail "Application prod-fleet not found"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/prod-fleet --timeout=90s >/dev/null 2>&1 || fail "prod-fleet is not Synced"
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/prod-fleet --timeout=90s >/dev/null 2>&1 || fail "prod-fleet is not Healthy"
kubectl -n starfleet get deployment prod-git-probe -o json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=d["spec"]["template"]["spec"]["containers"][0]
cpu=c.get("resources",{}).get("requests",{}).get("cpu")
ok=d["spec"]["replicas"]==3 and c["image"].endswith(":3.12-alpine") and cpu=="25m"
sys.exit(0 if ok else 1)' || fail "prod-git-probe must have 3 replicas, tag 3.12-alpine and requests.cpu 25m"
echo "PASS: prod-fleet is Synced and Healthy and the live Deployment has the patched resource request"

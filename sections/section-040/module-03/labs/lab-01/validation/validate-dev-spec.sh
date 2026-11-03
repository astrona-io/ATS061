#!/usr/bin/env bash
# Check: Application dev-fleet builds the dev overlay with an image override and an annotation
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-03-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
[[ "$(app_field dev-fleet '{.spec.source.path}')" == "kustomize/overlays/dev" ]] || fail "dev-fleet spec.source.path must be kustomize/overlays/dev"
[[ "$(app_field dev-fleet '{.spec.source.kustomize.images[0]}')" == "docker.io/library/python:3.12-alpine" ]] || fail "dev-fleet must override the image with docker.io/library/python:3.12-alpine"
kubectl -n argocd get application dev-fleet -o json 2>/dev/null | python3 -c '
import json,sys
a=json.load(sys.stdin)["spec"]["source"].get("kustomize",{}).get("commonAnnotations",{})
sys.exit(0 if a.get("fleet.starfleet/owner")=="operations" else 1)' || fail "commonAnnotations must set fleet.starfleet/owner to operations"
echo "PASS: Application dev-fleet builds the dev overlay with an image override and an annotation"

#!/usr/bin/env bash
# Check: A changed image is reverted and the hand-set replica count survives
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-050-01-01" ]]; then
  echo "FAIL: wrong Kubernetes context"; exit 1
fi
fail() { echo "FAIL: $1"; exit 1; }
app_field() { kubectl -n argocd get application "$1" -o "jsonpath=$2" 2>/dev/null; }
wait_until() { local tries="$1"; shift; local i; for ((i = 0; i < tries; i++)); do if "$@" >/dev/null 2>&1; then return 0; fi; sleep 3; done; return 1; }
kubectl -n starfleet get deployment git-probe >/dev/null 2>&1 || fail "Deployment git-probe does not exist"
kubectl -n starfleet scale deployment git-probe --replicas=4 >/dev/null 2>&1 || fail "could not scale git-probe"
kubectl -n starfleet set image deployment/git-probe git-probe=docker.io/library/python:3.12-alpine >/dev/null 2>&1 || fail "could not change the image"
image_is_repaired() { test "$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.template.spec.containers[0].image}')" = "docker.io/library/python:3.13-alpine"; }
wait_until 30 image_is_repaired || fail "Argo CD did not revert the image within 90 seconds"
[[ "$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}')" == "4" ]] || fail "the repair reset the replica count, so the sync did not respect the ignore rule"
echo "PASS: A changed image is reverted and the hand-set replica count survives"

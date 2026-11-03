#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-lab-010-01-01" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-lab-010-01-01" >&2
  exit 1
fi
auto="$(kubectl -n argocd get application mission -o jsonpath='{.spec.syncPolicy.automated.selfHeal}' 2>/dev/null)"
if [[ "$auto" != "true" ]]; then
  echo "FAIL: mission does not have automated sync with selfHeal: true"
  exit 1
fi
if ! kubectl -n starfleet get deployment git-probe >/dev/null 2>&1; then
  echo "FAIL: Deployment git-probe does not exist yet"
  exit 1
fi
kubectl -n starfleet scale deployment git-probe --replicas=4 >/dev/null 2>&1
for attempt in $(seq 1 18); do
  replicas="$(kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  if [[ "$replicas" == "2" ]]; then
    echo "PASS: Argo CD restored git-probe to 2 replicas after a manual change to 4"
    exit 0
  fi
  sleep 5
done
echo "FAIL: git-probe stayed at $replicas replicas; self-healing did not restore the declared 2"
exit 1

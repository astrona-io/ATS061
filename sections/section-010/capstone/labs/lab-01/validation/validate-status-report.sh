#!/usr/bin/env bash
# UNTESTED: written without running it against a cluster.
set -uo pipefail
if [[ "$(kubectl config current-context 2>/dev/null)" != "kind-astro-ats-061-capstone-010" ]]; then
  echo "FAIL: kubectl context is not kind-astro-ats-061-capstone-010" >&2
  exit 1
fi
report="$(kubectl -n argocd get configmap status-report -o json 2>/dev/null)" || { echo "FAIL: ConfigMap status-report not found in namespace argocd"; exit 1; }
live_pod="$(kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-repo-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
live_revision="$(kubectl -n argocd get application flight-deck -o jsonpath='{.status.sync.revision}' 2>/dev/null)"
printf '%s' "$report" | python3 -c '
import json,sys
live_pod,live_rev=sys.argv[1],sys.argv[2]
d=json.load(sys.stdin).get("data",{})
errors=[]
if not live_pod or d.get("repo-server-pod")!=live_pod: errors.append("repo-server-pod")
if d.get("controller-kind")!="StatefulSet": errors.append("controller-kind")
if not live_rev or d.get("flight-deck-revision")!=live_rev: errors.append("flight-deck-revision")
if errors:
    print("FAIL: status-report has wrong or missing keys: "+", ".join(errors)); sys.exit(1)
print("PASS: status-report names the repository server pod, the controller kind and the flight-deck revision")' "$live_pod" "$live_revision"

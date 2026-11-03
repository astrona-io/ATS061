#!/usr/bin/env bash
# Runs every check in validation/. Kept for the older smoke test.
set -uo pipefail
if [[ "$(kubectl config current-context)" != "kind-astro-ats-061-lab-040-01-01" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi
lab_directory="$(cd "$(dirname "$0")" && pwd)"
status=0
for script in "$lab_directory"/validation/validate-*.sh; do
  bash "$script" || status=1
done
exit "$status"

# Repair, Create And Report On Argo CD Applications

UNTESTED. This lab was validated statically with `astrona validate -c` and `bash -n` only. It was never booted, so the checks and the reference solution have not been run against a cluster. Run `astrona test` on it before you rely on it.

Capstone for section 010. Starting state: `flight-deck` has a wrong path, `hangar-cam` delivers `broken/bad-image` with pruning off, `mission-log` does not exist. The learner also writes a ConfigMap report from live cluster reads.

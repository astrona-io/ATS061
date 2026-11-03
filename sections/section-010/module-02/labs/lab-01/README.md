# Repair An Application With A Comparison Error

UNTESTED. This lab was validated statically with `astrona validate -c` and `bash -n` only. It was never booted, so the checks and the reference solution have not been run against a cluster. Run `astrona test` on it before you rely on it.

Starting state: the Application `fleet-registry` points at a missing path and a missing revision of the disposable Git source. The checks read the Application status and the delivered Deployment.

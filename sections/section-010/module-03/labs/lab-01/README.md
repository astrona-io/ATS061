# Correct An OutOfSync And Unhealthy Application

UNTESTED. This lab was validated statically with `astrona validate -c` and `bash -n` only. It was never booted, so the checks and the reference solution have not been run against a cluster. Run `astrona test` on it before you rely on it.

Starting state: the Application `bridge-cam` delivers `broken/bad-image` with pruning off. The fix moves it to `workloads/beta` and turns pruning on.

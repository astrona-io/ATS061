---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Prerequisites

You need `astrona`, `kubectl`, `kind`, Podman or Docker, `curl` and Python 3. The lab starts its own cluster, downloads a pinned Argo CD manifest and pulls container images, so it needs internet access.

A kubeconfig is the file that tells `kubectl` which cluster and credentials to use. Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-020-01-01`.

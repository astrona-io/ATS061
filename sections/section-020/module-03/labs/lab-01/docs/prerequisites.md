---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Prerequisites

You need `astrona`, `kubectl`, `kind`, Podman or Docker, `curl` and Python 3. The lab starts its own kind cluster, installs Argo CD from a pinned manifest and starts a disposable Git server inside the cluster, so the lab needs internet access to download the manifest and the container images.

Connect to the lab cluster before you start. A kubeconfig is the file that tells `kubectl` which cluster and credentials to use.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-020-03-01`. Every command in this lab runs against this cluster only.

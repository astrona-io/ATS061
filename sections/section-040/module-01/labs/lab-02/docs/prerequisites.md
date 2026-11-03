---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Prerequisites

You need `astrona`, `kubectl`, `kind`, Podman or Docker, `curl` and Python 3. The lab starts its own kind cluster, installs Argo CD from a pinned manifest and starts a disposable Git server inside the cluster, so it needs internet access for the manifest and the container images.

A kubeconfig is the file that tells `kubectl` which cluster and credentials to use. Connect before you start:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-01-02)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-01-02`. Every command in this lab runs against this cluster only.

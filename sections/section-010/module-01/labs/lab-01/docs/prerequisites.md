---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Prerequisites

You need astrona, kubectl, kind, Python 3, Podman or Docker and curl. The lab starts its own kind cluster, installs Argo CD from a pinned manifest and starts a disposable Git server inside the cluster, so it needs internet access.

Connect to the lab cluster before you start. A kubeconfig is the file that tells kubectl which cluster and credentials to use.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-010-01-01)"
kubectl config current-context
```

The context must be kind-astro-ats-061-lab-010-01-01.

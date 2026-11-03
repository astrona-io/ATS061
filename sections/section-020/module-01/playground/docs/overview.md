---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Playground: Manual And Automated Sync

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace. A Git server inside the cluster serves the seed repository at `http://git-source.argocd.svc:8080/repo.git`. The path `plain` declares the Deployment `git-probe` with two replicas and a Service `git-probe` for the `starfleet` namespace. No Application exists and nothing is graded.

Connect to the cluster:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-020-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-020-01`.

## Things to try

Create an Application for the path `plain` without a sync policy and read its `status.sync.status`. Sync it with `argocd app sync` in core mode, then read `status.operationState`. Scale the Deployment by hand and watch the Application become `OutOfSync`. Add `automated` with `selfHeal: true` and watch the replica count return to two. The seed repository is read-only, so to see pruning, create a second Application for the path `waves` and then change its path to `plain`; with `prune: true` the objects of `waves` are removed.

## Common pitfalls

> [!WARNING]
> The Git server is read-only, so you cannot commit a change. Change the Application instead. The cluster is shared by all exercises in this playground, so delete an Application before you create another one that manages the same object names.

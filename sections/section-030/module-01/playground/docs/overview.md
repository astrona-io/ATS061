---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Playground: Application Source, Destination And Project Boundaries

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The server holds the branches `main` and `release`, the path `plain` with the Deployment and Service `git-probe` (two replicas on `main`, three on `release`) and the paths `workloads/alpha`, `workloads/beta` and `workloads/gamma`. The namespaces `starfleet` and `outpost` exist. No Application exists and no project besides `default`. Nothing is graded.

Connect to the cluster:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-030-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-030-01`.

## Things to try

Create an Application with `spec.source.targetRevision: main`, read `status.sync.revision`, and change the revision to `release` with `kubectl patch`. Create an AppProject that allows only the namespace `outpost` and an Application in it that targets `starfleet`, then read `status.conditions`. Add the namespace to the project and watch the Application sync. Set `namespaceResourceBlacklist` to deny `Service` and see how the Application reports the refused kind.

## Common pitfalls

> [!WARNING]
> Conditions on an Application appear after the next refresh, which can take a few seconds. A merge patch replaces a whole list, so include every entry you want to keep.

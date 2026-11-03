---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Playground: Tracking, Finalizers, App Of Apps And Health

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The server holds the paths `workloads/alpha`, `workloads/beta` and `workloads/gamma`, the path `apps` with the child Application manifests `alpha.yaml` and `beta.yaml`, and the path `broken/bad-image` with a Deployment whose image does not exist. The namespaces `starfleet` and `outpost` exist. No Application exists and nothing is graded.

Connect to the cluster:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-030-03)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-030-03`.

## Things to try

Create an Application for `workloads/alpha` and read the annotation `argocd.argoproj.io/tracking-id` on its Deployment. Create a parent Application for the path `apps` with the destination namespace `argocd` and read the tracking annotation of a child. Delete an Application with and without the finalizer `resources-finalizer.argocd.argoproj.io` and check whether the Deployment stays. Create an Application for `broken/bad-image` and compare `status.health.status` with the pod state.

## Common pitfalls

> [!WARNING]
> Leftover Deployments from an earlier try can hide a later result, so list the Deployments in `starfleet` between exercises. A health failure can take about ten minutes to show as `Degraded`.

---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Playground: App Of Apps

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` holds the path `apps` with the Application manifests `alpha.yaml` and `beta.yaml`, and the paths `workloads/alpha`, `workloads/beta` and `workloads/gamma`, each with a Deployment and a Service in the namespace `starfleet`. The path `broken/bad-image` holds a Deployment with an image tag that does not exist. No Application exists and nothing is graded.

Connect to the cluster and select the namespace `argocd`:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-050-02)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-050-02`.

## Things to try

Create a parent Application with the path `apps` and the destination namespace `argocd`, with automated sync, prune and self-heal. Read `kubectl -n argocd get applications` and the `tracking-id` annotation of a child and of a Deployment.

Patch a child with `kubectl patch application alpha --type merge` and see that the parent reverts it. Delete a child and see it return. Delete the parent and see that the children stay. Add the finalizer `resources-finalizer.argocd.argoproj.io` to a child and delete it to see the Deployment go with it.

Create an Application for `broken/bad-image` and compare its `Degraded` health with the `ComparisonError` of an Application that points to a path that does not exist.

## Common pitfalls

> [!WARNING]
> Two Applications that deploy the same object make Argo CD report a shared resource and fight over it. Delete the old Application and the workloads before you create the next parent, so each object has one owner.

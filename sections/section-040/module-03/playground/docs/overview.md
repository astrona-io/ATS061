---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Playground: Kustomize Overrides And Rendered Manifests

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` and the tag `v1.0.0` hold the Kustomize base `kustomize/base` and the overlays `kustomize/overlays/dev` and `kustomize/overlays/prod`. The namespace `starfleet` exists. No Application exists and nothing is graded.

Connect to the cluster:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-040-03)"
kubectl config set-context --current --namespace=argocd
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-040-03`.

## Things to try

Create an Application for an overlay and add `images`, `replicas`, `commonLabels`, `commonAnnotations` and `namePrefix` under `spec.source.kustomize`. Print the result with `argocd app manifests NAME --core` and compare it with `kubectl get`. Add an inline patch and remove the namespace from it to see the build fail. Scale a Deployment by hand and read `argocd app diff NAME --core`. Add the same override to two Applications and check that the Git server is unchanged. Use the annotation `argocd.argoproj.io/refresh=hard` to force a new render.

## Common pitfalls

> [!WARNING]
> Two Applications that render the same object fight over it. The dev and prod overlays use different name prefixes, so they can run side by side, but two Applications for one overlay cannot. Delete an Application before you create another one for the same overlay.

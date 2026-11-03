---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Playground: Directory, Helm And Kustomize Sources And ignoreDifferences

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The server holds a Helm chart in `chart` (default two replicas, `values-prod.yaml` with three), a Kustomize base in `kustomize/base` with the overlays `dev` and `prod`, plain manifests in `workloads/alpha`, `workloads/beta` and `workloads/gamma`, and the path `plain`, which holds a `kustomization.yaml`. The namespaces `starfleet` and `outpost` exist. No Application exists and nothing is graded.

Connect to the cluster and set the `argocd` namespace for the `argocd` command line client:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-030-02)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-030-02`.

## Things to try

Create one Application for each source type and read `status.sourceType`. Render the chart with `valueFiles`, `valuesObject` and `parameters` and read `argocd app manifests NAME --core` after each change to see which value wins. Override `namePrefix` and `images` on a Kustomize overlay. Add `spec.ignoreDifferences` for `/spec/replicas`, scale the Deployment by hand and watch the Application stay `Synced`. Add `RespectIgnoreDifferences=true` and start a manual sync.

## Common pitfalls

> [!WARNING]
> `argocd app manifests` needs `--core` and the `argocd` namespace in the `kubectl` context. A merge patch replaces a whole list such as `parameters`.

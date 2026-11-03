---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Playground: Helm And Kustomize Sources

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` holds a Helm chart in `chart` (with the extra values file `values-prod.yaml`), a Kustomize base in `kustomize/base` with the overlays `kustomize/overlays/dev` and `kustomize/overlays/prod`, and a Kustomize directory in `plain`. The namespaces `starfleet` and `outpost` exist. No Application exists and nothing is graded.

Connect to the cluster and make the `argocd` namespace the default for `kubectl`:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-040-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-040-01`.

## Things to try

Create an Application for the path `chart` and read `status.sourceType`, `status.sync.revision` and `status.summary.images`. Add `helm.valueFiles` with `values-prod.yaml` and watch the replica count of the Deployment `git-probe` change from 2 to 3. Search the cluster for a Helm release Secret with `kubectl get secrets --all-namespaces --field-selector type=helm.sh/release.v1` and confirm that none exists.

Create Applications for `kustomize/overlays/dev` and `kustomize/overlays/prod` and compare the Deployment names, the label `environment` and the replica counts. Create an Application for `plain` and check that Argo CD reports `Kustomize` for it, because the directory holds a `kustomization.yaml`. Print the rendered manifests of an Application with `argocd app manifests NAME --core` and compare them with the live objects.

## Common pitfalls

> [!WARNING]
> The `argocd` command in core mode needs `--core` on every command and the namespace `argocd` in the `kubectl` context. Without them it tries to reach an Argo CD server that is not exposed. Two Applications that render the same object name in the same namespace fight over that object, so give each Application its own overlay or chart output.

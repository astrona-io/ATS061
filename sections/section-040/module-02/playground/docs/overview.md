---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Playground: Helm Values, Parameters And Release Settings

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` holds the Helm chart `chart` with the defaults `replicas: 2` and the image tag `3.13-alpine`, and a second values file `values-prod.yaml` with `replicas: 3`. The namespaces `starfleet` and `outpost` exist. No Application exists and nothing is graded.

Connect to the cluster:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-040-02)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-040-02`.

## Things to try

Create an Application for the chart with `valueFiles`, `valuesObject` and `parameters` that all set `replicas`, and check which value the Deployment gets. Remove the layers one at a time with `kubectl patch` and watch the replica count change. Set `releaseName` and check that the object names do not change, because the chart never reads the release name. Point `valueFiles` at a file that does not exist and read `status.conditions`. Then set `ignoreMissingValueFiles: true` and see the error disappear. Use a destination namespace that differs from the namespace in the chart and find out where the objects land.

## Common pitfalls

> [!WARNING]
> Two Applications that render the same object, such as the Deployment `git-probe`, fight over it. Delete the first Application before you create a second one for the same chart, and use `kubectl get application NAME -o yaml` to read an Application before you patch it.

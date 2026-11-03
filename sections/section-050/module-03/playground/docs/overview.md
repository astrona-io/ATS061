---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Playground: ApplicationSet

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace, including the ApplicationSet controller, and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` holds the files `envs/dev/config.json`, `envs/staging/config.json` and `envs/prod/config.json` with the fields `environment` and `replicas`, the Kustomize base `kustomize/base` with the Deployment and Service `git-probe`, and the paths `workloads/alpha`, `workloads/beta` and `workloads/gamma`. No Application or ApplicationSet exists and nothing is graded.

Connect to the cluster and select the namespace `argocd`:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-050-03)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-050-03`.

## Things to try

Create an ApplicationSet with a list generator and a template that uses `{{ .service }}` in the name and the path. Replace it with a Git files generator for `envs/*/config.json` and use the parameters `environment` and `replicas` in the name, the Kustomize namespace and the Kustomize replicas.

Read `kubectl -n argocd describe applicationset NAME`, the owner reference of a generated Application and the tracking annotation of its Deployment. Edit and delete a generated Application and watch the ApplicationSet controller repair it. Change the path pattern to one that matches nothing and see the Applications disappear. Delete the ApplicationSet and see the Applications go.

## Common pitfalls

> [!WARNING]
> Use a unique Application name and a unique namespace in the template for each parameter set. If two sets render the same name, one Application cannot be created. If they share one namespace and workload names, the Applications fight over the same objects.

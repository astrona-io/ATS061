---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Playground: Drift, Refresh And Ignore Rules

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` holds the path `plain` with the Deployment and Service `git-probe` in the namespace `starfleet`. The Deployment has two replicas and the image `docker.io/library/python:3.13-alpine`. No Application exists and nothing is graded.

Connect to the cluster and select the namespace `argocd` for the `argocd` client in core mode:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-050-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-050-01`.

## Things to try

Create an Application for `plain` without a sync policy. Scale the Deployment by hand and compare `kubectl -n argocd get application NAME -o jsonpath='{.status.sync.status}'` before and after `argocd app get NAME --refresh --core`. Add the annotation `argocd.argoproj.io/refresh=hard` to the Application with `kubectl annotate` and see that the controller removes it again.

Turn on automated sync with `selfHeal: true`, scale the Deployment by hand and watch Argo CD revert it. Then add an `ignoreDifferences` rule for `/spec/replicas` of `Deployment` in the group `apps`, scale again and see that the count stays. Change the image and see that Argo CD repairs it. Add `RespectIgnoreDifferences=true` and check that the repair no longer resets the replica count.

Add an annotation to the Deployment by hand and check that the Application stays `Synced`, because Git does not declare the annotation.

## Common pitfalls

> [!WARNING]
> Delete the Application with `kubectl` and then delete the Deployment and Service `git-probe` before you try another variant. An Application without a finalizer leaves its objects in the cluster, and the next experiment would start from the old live state.

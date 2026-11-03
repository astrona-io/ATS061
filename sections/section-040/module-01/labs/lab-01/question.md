---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Render A Helm Chart With A Production Values File

The `git-probe` service of Starfleet runs two replicas by default. The station is entering a busy period, and operations must run it with the production replica count, which the chart keeps in a separate values file. Argo CD must render the chart and own the result. Nobody may install it with Helm by hand.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds a Helm chart in the path `chart` on the branch `main`. The chart has the default file `values.yaml` and a second file `values-prod.yaml`. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-01-01`.

## Required result

- An Application `mission` in the `argocd` namespace uses the project `default`, the repository above, the revision `main` and the path `chart`, and deploys to `https://kubernetes.default.svc` in the namespace `starfleet`.
- The Application passes the file `values-prod.yaml` to Helm as a values file.
- The Application has automated sync with `prune: true` and `selfHeal: true`.
- The Application is `Synced` and `Healthy`, and Argo CD reports `Helm` as its source type.
- The Deployment `git-probe` in `starfleet` has 3 available replicas and still runs the chart default image `docker.io/library/python:3.13-alpine`.

## Constraints

Do not change the Git server and do not install anything with the `helm` command. Do not create other Applications.

---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Layer Helm Values For The Fleet Chart

The Starfleet outpost team runs the `git-probe` chart through Argo CD. The production file `values-prod.yaml` sets three replicas, but a storm forecast needs four, and the team wants the image pinned to the older tag `3.12-alpine`. The team does not want to edit the chart in Git. All three changes must come from the Application itself, and the Application is recorded under the `outpost` namespace.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds a Helm chart in the path `chart` on the branch `main`, with the files `values.yaml` and `values-prod.yaml`. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-02-01`.

## Required result

- An Application `fleet-chart` in the `argocd` namespace uses the project `default`, the repository above, the revision `main` and the path `chart`. Its destination is `https://kubernetes.default.svc` and the namespace `outpost`. It has automated sync with `prune: true` and `selfHeal: true`.
- The Application passes `values-prod.yaml` as a values file, sets the image tag `3.12-alpine` in `valuesObject`, and sets the replica count 4 as a Helm parameter named `replicas`.
- The Application is `Synced` and `Healthy`, and Argo CD reports `Helm` as its source type.
- The Deployment `git-probe` has 4 available replicas and runs the image `docker.io/library/python:3.12-alpine`. It and the Service `git-probe` are in the namespace `starfleet`, and the namespace `outpost` holds no Deployment.

## Constraints

Do not change the Git server and do not install anything with the `helm` command. Do not create other Applications.

---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Repair And Extend The Fleet Rendering Setup

The fleet team deploys the `git-probe` service through Argo CD from Helm and Kustomize sources. The Application `fleet-chart` was created by a colleague and never reached a healthy state. The team also needs a development and a production deployment from the Kustomize overlays, and the settings for both must live in the Applications, not in new commits.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the Helm chart `chart` with the values files `values.yaml` and `values-prod.yaml`, and the Kustomize overlays `kustomize/overlays/dev` and `kustomize/overlays/prod`, all on the branch `main`. The Application `fleet-chart` exists and reports an error. The namespace `starfleet` exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-040)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-040`.

## Required result

- The Application `fleet-chart` renders without error. It passes the values file `values-prod.yaml`, sets the image tag `3.12-alpine` in `valuesObject` and sets the Helm parameter `replicas` to 4. It is `Synced` and `Healthy`, and the Deployment `git-probe` in `starfleet` has 4 available replicas and the image `docker.io/library/python:3.12-alpine`.
- An Application `bridge-dev` builds `kustomize/overlays/dev` and overrides the image with `docker.io/library/python:3.12-alpine`. It is `Synced` and `Healthy`, and the Deployment `dev-git-probe` has 1 replica and that image.
- An Application `bridge-prod` builds `kustomize/overlays/prod` and sets the replicas of the base Deployment `git-probe` to 2 in the Application. It is `Synced` and `Healthy`, and the Deployment `prod-git-probe` has 2 available replicas.
- None of the three Applications reports a `ComparisonError`.
- All three Applications use the project `default`, the branch `main`, the destination namespace `starfleet` and automated sync with `prune: true` and `selfHeal: true`.

## Constraints

Do not change the Git server. Do not install anything with the `helm` command or apply the overlays with `kustomize`. Create only the Applications named above.

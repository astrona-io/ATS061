---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Override Kustomize Overlays From Two Applications

The Starfleet operations team deploys the `git-probe` service from two Kustomize overlays in Git. The development overlay must run the older image tag `3.12-alpine` and carry an owner annotation. The production overlay must request a small amount of processor time so that the scheduler can place it on a crowded node. The overlays in Git must stay unchanged. Both changes must live in the Applications.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the overlays `kustomize/overlays/dev` and `kustomize/overlays/prod` on the branch `main`. The namespace `starfleet` exists. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-03-01`.

## Required result

- An Application `dev-fleet` in the `argocd` namespace builds the path `kustomize/overlays/dev` of the branch `main` for the namespace `starfleet`. It overrides the image with `docker.io/library/python:3.12-alpine` and sets the common annotation `fleet.starfleet/owner` to `operations`.
- An Application `prod-fleet` in the `argocd` namespace builds the path `kustomize/overlays/prod` of the branch `main` for the namespace `starfleet`. An inline patch sets the container resource request `cpu` to `25m` on the base Deployment `git-probe`.
- Both Applications use the project `default` and automated sync with `prune: true` and `selfHeal: true`. Both are `Synced` and `Healthy`.
- The live Deployment `dev-git-probe` has 1 replica, the tag `3.12-alpine` and the annotation. The live Deployment `prod-git-probe` has 3 replicas, the tag `3.12-alpine` and the request `25m`.

## Constraints

Do not change the Git server and do not run `kustomize` or `kubectl apply` against the `starfleet` namespace yourself. Create only the two Applications.

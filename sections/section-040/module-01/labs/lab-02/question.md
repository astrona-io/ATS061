---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Deploy A Kustomize Overlay With Argo CD

The `git-probe` service has one base and two overlays, one for development and one for production. Starfleet needs the production variant on the cluster: three replicas, the pinned older image tag and the production label. The Application must deploy the production overlay and not the base.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds a Kustomize base in `kustomize/base` and the overlays `kustomize/overlays/dev` and `kustomize/overlays/prod` on the branch `main`. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-01-02)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-01-02`.

## Required result

- An Application `mission` in the `argocd` namespace uses the project `default`, the repository above, the revision `main` and the path of the production overlay, and deploys to `https://kubernetes.default.svc` in the namespace `starfleet`.
- The Application has automated sync with `prune: true` and `selfHeal: true`, and it is `Synced` and `Healthy`. Argo CD reports `Kustomize` as its source type.
- The Deployment `prod-git-probe` in `starfleet` has 3 available replicas, the label `environment=prod` and the image `docker.io/library/python:3.12-alpine`. The Service `prod-git-probe` exists.
- The Deployment `git-probe` from the base does not exist.

## Constraints

Do not change the Git server and do not add Kustomize settings to the Application. Do not create other Applications.

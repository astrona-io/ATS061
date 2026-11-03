---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Override A Helm Chart And A Kustomize Overlay And Ignore Replicas

Starfleet runs the `git-probe` service in production from a Helm chart and in a development copy from a Kustomize overlay. Production must use the values file for three replicas and the older image tag `3.12-alpine`. A future autoscaler will own the replica count in production, so Argo CD must not treat a changed replica count as drift. The development copy must run the same older image.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the Helm chart in `chart` with the values file `values-prod.yaml`, and the Kustomize overlay `kustomize/overlays/dev` on the branch `main`. The namespace `starfleet` exists. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-030-02-01`.

## Required result

- An Application `probe-prod` in `argocd` uses the project `default`, the repository above, the revision `main` and the path `chart`, and deploys to `https://kubernetes.default.svc` and the namespace `starfleet`. It uses the values file `values-prod.yaml` and a Helm parameter `image.tag` with the value `3.12-alpine`. Its sync policy is automated with `selfHeal: true`. It ignores differences in `/spec/replicas` of Deployments of the group `apps`. It is `Synced` and `Healthy`, and the Deployment `git-probe` has `3` replicas and the image `docker.io/library/python:3.12-alpine`.
- When someone scales the Deployment `git-probe` by hand, `probe-prod` stays `Synced` and the replica count stays as it was set.
- An Application `probe-dev` in `argocd` uses the project `default`, the revision `main` and the path `kustomize/overlays/dev`, deploys to the same cluster and namespace, and has an automated sync policy. It overrides the image with a Kustomize image override so that the image is `docker.io/library/python:3.12-alpine`. It is `Synced` and `Healthy`, and the Deployment `dev-git-probe` has `1` replica and that image.

## Constraints

Do not change anything in Git. Make the changes in the Applications. Use the values file for the replica count: do not set the replica count in `valuesObject` or in a parameter.

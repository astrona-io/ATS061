---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Bring The Bridge Systems Under Argo CD Control

Starfleet runs the `git-probe` service of the bridge and the services `alpha` and `beta` of the engineering deck. All of them must be managed by Argo CD from Git. The bridge service must run in a restricted project, use the production chart settings and tolerate a manual scale-up during an incident. The engineering services must come from one parent Application, so that nobody creates them by hand.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the paths `chart`, `apps`, `workloads/alpha` and `workloads/beta` on the branch `main`. The path `chart` is a Helm chart with the file `values-prod.yaml`. The namespaces `starfleet` and `outpost` exist. No Application and no project besides `default` exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-030)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-030`.

## Required result

- An AppProject `bridge` allows exactly one source repository, the repository above, and exactly one destination, the server `https://kubernetes.default.svc` with the namespace `starfleet`. It allows only the namespaced kinds Deployment of the group `apps` and Service of the empty group.
- An Application `probe-chart` in the project `bridge` uses the revision `main` and the path `chart`, applies the values file `values-prod.yaml` and sets the Helm parameter `image.tag` to `3.12-alpine`. It deploys to `starfleet`. Its sync policy is automated with `selfHeal: true`. It has the finalizer `resources-finalizer.argocd.argoproj.io`. It is `Synced` and `Healthy` without conditions. The Deployment `git-probe` has `3` replicas and uses the image `docker.io/library/python:3.12-alpine`.
- When someone scales the Deployment `git-probe` by hand, Argo CD does not report drift and does not scale it back. The Application stays `Synced`.
- An Application `fleet` in the project `default` uses the path `apps` and deploys to the namespace `argocd`. Its sync policy is automated with `prune: true` and `selfHeal: true`, and it has the finalizer `resources-finalizer.argocd.argoproj.io`. The child Applications `alpha` and `beta` were created by `fleet` and are `Synced` and `Healthy`.
- The Deployment `git-probe` carries the tracking annotation `argocd.argoproj.io/tracking-id` that names the Application `probe-chart` as its owner. The Application `alpha` carries the annotation that names `fleet` as its owner.

## Constraints

Use `kubectl` only. Do not apply the child Application manifests yourself. Do not create the Deployments by hand. Do not use `valuesObject`.

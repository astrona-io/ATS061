---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Deliver A Git Sourced Application With Argo CD

The Starfleet operations team wants the `git-probe` workload in the `starfleet` namespace delivered from Git instead of applied by hand. Create one Argo CD Application that reads the manifests, keeps the cluster equal to Git and reverts manual changes.

## Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-010-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-010-01-01`.

## Starting state

- Argo CD is installed in the `argocd` namespace. Its API server, repository server, application controller and Redis run.
- A disposable Git server inside the cluster serves one repository at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` has a directory `plain` with a Deployment and a Service named `git-probe`. You cannot commit to this repository.
- No Application exists and no `git-probe` Deployment exists in `starfleet`.

## Required result

- An Application named `mission` in the `argocd` namespace, in the project `default`, reads the directory `plain` of the branch `main` and deploys to the namespace `starfleet` of the local cluster.
- The Application has automated sync with pruning and self-healing.
- The Application is `Synced` and `Healthy`, and `status.sync.revision` holds a commit hash.
- The Deployment `git-probe` has 2 available replicas, and Argo CD tracks it for `mission`.
- A manual change of the live replica count is reverted by Argo CD.

## Constraints

- Do not create the `git-probe` Deployment or Service yourself. Argo CD must create them.
- Do not change or scale any Argo CD component.

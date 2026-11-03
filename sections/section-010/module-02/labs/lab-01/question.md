---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Repair An Application With A Comparison Error

The Starfleet registry team asked Argo CD to deliver the `git-probe` workload to the `starfleet` namespace. The request has been stuck since launch. Nothing runs in `starfleet`, and the Application does not show a sync result. Find out why Argo CD cannot render the source and repair the Application.

## Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-010-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-010-02-01`.

## Starting state

- Argo CD is installed in the `argocd` namespace with its API server, repository server, application controller, ApplicationSet controller and Redis.
- A disposable Git server inside the cluster serves one repository at `http://git-source.argocd.svc:8080/repo.git`. It has the branch `main`, the branch `release` and the tag `v1.0.0`. The directory `plain` holds the manifests of the `git-probe` Deployment and Service. You cannot commit to this repository.
- The Application `fleet-registry` exists in the `argocd` namespace. Its sync status is `Unknown` and it reports an error condition.

## Required result

- The Application `fleet-registry` keeps its name and project `default` and reads the directory `plain` at the tag `v1.0.0` of the repository above.
- The Application compares without a `ComparisonError` condition and its sync status is `Synced`.
- `status.sync.revision` holds a commit hash.
- The Deployment `git-probe` in `starfleet` has 2 available replicas, Argo CD tracks it for `fleet-registry`, and the Application health status is `Healthy`.

## Constraints

- Keep automated sync with pruning and self-healing enabled.
- Do not change, scale or restart any Argo CD component.
- Do not create the `git-probe` Deployment yourself. Argo CD must deliver it.

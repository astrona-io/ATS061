---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Repair, Create And Report On Argo CD Applications

The Starfleet platform team runs three Applications on one Argo CD installation. One cannot render its source, one delivers a broken workload, and one does not exist yet. Repair the first two, create the third and record what you read from Argo CD in a report.

## Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-010)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-010`.

## Starting state

- Argo CD is installed in the `argocd` namespace. A disposable Git server inside the cluster serves one repository at `http://git-source.argocd.svc:8080/repo.git` with the branch `main`. You cannot commit to it.
- The directories `plain`, `workloads/beta` and `workloads/gamma` hold working manifests. The directory `broken/bad-image` holds a Deployment whose image tag does not exist.
- The Application `flight-deck` should deliver the `git-probe` workload but reports an error and has no sync result.
- The Application `hangar-cam` delivers `broken/bad-image` and has automated sync without pruning. Its workload never becomes ready.
- No Application named `mission-log` exists.

## Required result

- `flight-deck` compares the directory `plain`, is `Synced` and `Healthy`, and the Deployment `git-probe` in `starfleet` has 2 available replicas.
- `hangar-cam` compares the directory `workloads/beta`, is `Synced` and `Healthy`, and the Deployment `bad-image` no longer exists.
- A new Application `mission-log` in the `argocd` namespace delivers the directory `workloads/gamma` of the branch `main` to `starfleet` with the project `default` and automated sync with pruning and self-healing. It is `Synced` and `Healthy`, and Argo CD tracks the `gamma` Deployment for it.
- A ConfigMap `status-report` in the `argocd` namespace has three keys: `repo-server-pod` is the name of the running repository server pod, `controller-kind` is the Kubernetes kind that runs the application controller, and `flight-deck-revision` is the commit hash that `flight-deck` is synced to.

## Constraints

- Keep the names of the existing Applications and do not delete them.
- Do not scale, restart or edit any Argo CD component.
- Argo CD must create and remove the workloads. Do not create or delete them directly.

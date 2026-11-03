---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Correct An OutOfSync And Unhealthy Application

The camera feed of the `bridge` was published with an image tag that does not exist. The Application `bridge-cam` still delivers that broken Deployment. The corrected `beta` workload is already in the `main` branch of the Git source, but the Application does not use it. Move the Application to the corrected workload and make Argo CD remove the broken one.

## Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-010-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-010-03-01`.

## Starting state

- Argo CD is installed in the `argocd` namespace. A disposable Git server inside the cluster serves one repository at `http://git-source.argocd.svc:8080/repo.git`. You cannot commit to it.
- The Application `bridge-cam` reads the directory `broken/bad-image` of the branch `main`. It has automated sync without pruning and without self-healing.
- The Deployment `bad-image` in `starfleet` cannot pull its image, so its pods never become ready. The Application is not `Healthy`.
- The directory `workloads/beta` of the branch `main` holds a working `beta` Deployment and Service.

## Required result

- The Application `bridge-cam` compares the directory `workloads/beta` of the branch `main`.
- The Deployment `beta` in `starfleet` has 1 available replica and Argo CD tracks it for `bridge-cam`.
- The Deployment `bad-image` no longer exists, and Argo CD removed it.
- The Application has sync status `Synced` and health status `Healthy`.

## Constraints

- Keep the Application name, project and destination.
- Do not delete the Application and do not delete or create workload objects with `kubectl`. Argo CD must create and remove them.

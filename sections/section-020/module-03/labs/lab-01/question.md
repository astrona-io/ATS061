---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Freeze Automated Syncs And Roll Back A Release

Starfleet freezes unattended deployments during a station maintenance period. The `alpha` workload must not sync by itself in that period, and a failed sync must retry a few times. A second service, `release-train`, was deployed from the `release` branch with three replicas, and the fleet wants it back on the two replicas of `main` without a new commit.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the paths `workloads/alpha` and `plain` on the branches `main` and `release`. No Application and no project besides `default` exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-020-03-01`.

## Required result

- An AppProject `maintenance` in `argocd` allows any source repository and any namespace of `https://kubernetes.default.svc`, and has one `deny` sync window that is active at all times for all Applications (schedule `* * * * *`, duration `24h`) with `manualSync: true`.
- An Application `frozen` uses the project `maintenance`, the repository above, the revision `main` and the path `workloads/alpha`, and deploys to the namespace `starfleet`. Its sync policy is automated with `prune: true` and a retry policy with limit `3` and a backoff with duration `10s`, factor `2` and maximum duration `2m`. The window blocks it: the Application stays `OutOfSync`, no sync operation exists and the Deployment `alpha` does not exist.
- An Application `release-train` uses the project `default`, the repository above, the revision `main` and the path `plain`, and deploys to the namespace `starfleet`. It has no automated sync. Its history holds a sync of `release` and a later sync of the revision of `main` that was deployed first. The Deployment `git-probe` has `2` replicas.

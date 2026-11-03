---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Run A Controlled Release Of The Fleet

The fleet runs three services through Argo CD. The ordered service `main-deck` must deploy in a fixed order with its checks and repair itself when someone changes it by hand. The service `cargo-bay` must not sync unattended during the station freeze. The service `fleet-release` was deployed from the wrong branch and must go back to its first revision without a new commit.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the paths `waves`, `workloads/beta` and `plain` on the branches `main` and `release`. The path `waves` holds the objects of `main-deck` with their waves and hooks. No Application and no project besides `default` exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-020)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-020`.

## Required result

- An Application `main-deck` uses the project `default`, the repository above, the revision `main` and the path `waves`, and deploys to the namespace `starfleet`. Its sync policy is automated with `prune: true` and `selfHeal: true`, and its sync options include `CreateNamespace=true` and `PruneLast=true`. It is `Synced` and `Healthy`, its last operation lists a `PreSync` and a `PostSync` hook, and the hook Jobs are deleted. When someone changes the replicas of the Deployment `wave-app` by hand, Argo CD sets them back to `1`.
- An AppProject `freeze` allows any source repository and any namespace of `https://kubernetes.default.svc`, and has one `deny` window with the schedule `* * * * *`, the duration `24h`, all Applications and `manualSync: true`.
- An Application `cargo-bay` uses the project `freeze`, the revision `main` and the path `workloads/beta`, and deploys to `starfleet`. Its sync policy is automated with a retry policy of limit `2`. The window blocks it: it is `OutOfSync`, has no sync operation and the Deployment `beta` does not exist.
- An Application `fleet-release` uses the project `default`, the revision `main` and the path `plain`, with no automated sync. Its history holds a sync of `release` and a later sync of the first revision of `main`, and the Deployment `git-probe` has `2` replicas.

---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Repair Live Drift With Self Healing

The `git-probe` workload in `starfleet` must always run the two replicas that Git declares. An engineer scaled it down by hand during a test and nobody noticed. Create an Application that keeps the workload in the declared state without human help.

## Starting state

Argo CD is installed in the `argocd` namespace. A Git server inside the cluster holds the path `plain` on the branch `main` at `http://git-source.argocd.svc:8080/repo.git`. That path declares the Deployment `git-probe` with two replicas. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-020-01-01`.

## Required result

- An Application named `mission` exists in the `argocd` namespace. It uses the project `default`, the repository above, the revision `main` and the path `plain`, and it deploys to the `starfleet` namespace of the cluster `https://kubernetes.default.svc`.
- Its sync policy is automated with `prune` and `selfHeal` both set to `true`.
- The Application is `Synced` and `Healthy`, and the Deployment `git-probe` has two available replicas.
- After you scale the Deployment to one replica, Argo CD restores two replicas without any further command from you.

## Constraints

Do not edit the Deployment directly to set it back to two replicas. The grader checks the Application and the live Deployment.

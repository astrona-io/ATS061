---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Bootstrap The Fleet With An App Of Apps

The Starfleet operations team wants the services `alpha` and `beta` on the station deployed from one place. A single parent Application named `fleet-root` must create both service Applications from Git, and it must repair them when someone edits or deletes one by hand.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the Application manifests `alpha.yaml` and `beta.yaml` in the path `apps` of the branch `main`. Each manifest creates an Application that deploys the path `workloads/alpha` or `workloads/beta` to the namespace `starfleet`. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-050-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-050-02-01`.

## Required result

- An Application `fleet-root` in `argocd` uses the project `default`, the repository above, the revision `main` and the path `apps`, and its destination is the cluster `https://kubernetes.default.svc` and the namespace `argocd`.
- `fleet-root` has automated sync with `prune: true` and `selfHeal: true`.
- The Applications `alpha` and `beta` exist, are created by `fleet-root` (their tracking annotation names it as owner) and are `Synced` and `Healthy`. The Deployments `alpha` and `beta` in `starfleet` have one available replica each.
- If someone changes the revision of the live Application `alpha`, the parent sets it back to `main`.
- If someone deletes the live Application `beta`, the parent creates it again, and the Deployment `beta` is not removed in the meantime.

## Constraints

- Do not create the Applications `alpha` and `beta` yourself. Only `fleet-root` may create them.
- Do not add a finalizer to the parent or to the children.

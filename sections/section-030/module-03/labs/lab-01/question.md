---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Build An App Of Apps And Retire A Scratch Application

Starfleet wants one parent Application that creates the Applications of the `alpha` and `beta` services from Git, so that nobody creates them by hand. The test deployment `gamma`, which belongs to the Application `scratch`, is no longer needed and must be retired together with its workload.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the path `apps` with the manifests of the child Applications `alpha` and `beta` on the branch `main`. The Application `scratch` exists. It has the finalizer `resources-finalizer.argocd.argoproj.io` and deploys the Deployment `gamma` to the namespace `starfleet`. No other Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-030-03-01`.

## Required result

- An Application `fleet` in `argocd` uses the project `default`, the repository above, the revision `main` and the path `apps`, and deploys to `https://kubernetes.default.svc` and the namespace `argocd`. Its sync policy is automated with `prune: true` and `selfHeal: true`. It has the finalizer `resources-finalizer.argocd.argoproj.io`. It is `Synced` and `Healthy`.
- The child Applications `alpha` and `beta` exist, were created from Git by `fleet`, and are `Synced` and `Healthy`. The Deployments `alpha` and `beta` exist in `starfleet`.
- The Application `alpha` carries the tracking annotation `argocd.argoproj.io/tracking-id` with the value that names `fleet` as its owner, and the Deployment `alpha` carries the annotation that names the Application `alpha` as its owner.
- The Application `scratch` does not exist, and the Deployment `gamma` does not exist.

## Constraints

Create the children through the parent: do not apply the child manifests yourself. Retire `scratch` by deleting the Application only. Do not delete the Deployment `gamma` directly.

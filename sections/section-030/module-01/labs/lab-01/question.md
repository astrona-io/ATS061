---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Restrict An Application To One Repository, Namespace And Kinds

Starfleet lets the `mission` team deploy the `git-probe` service from the internal Git server. The team must not be able to use any other repository, any other namespace or any kind of object besides a Deployment and a Service. You create the project that enforces this and the Application that deploys inside it.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the path `plain` on the branch `main`, with the Deployment and the Service `git-probe` for the namespace `starfleet`. No Application and no project besides `default` exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-030-01-01`.

## Required result

- An AppProject `mission` in `argocd` allows exactly one source repository, `http://git-source.argocd.svc:8080/repo.git`, and exactly one destination, the cluster `https://kubernetes.default.svc` with the namespace `starfleet`. It allows exactly two namespaced kinds with `namespaceResourceWhitelist`: `Deployment` of the group `apps` and `Service` of the core group.
- An Application `mission` in `argocd` belongs to the project `mission`. It uses the repository above, the revision `main` and the path `plain`, and deploys to `https://kubernetes.default.svc` and the namespace `starfleet`. Its sync policy is automated with `prune: true` and `selfHeal: true`.
- The Application is `Synced` and `Healthy`, has no error conditions, records a commit SHA in `status.sync.revision`, and manages only the Deployment and the Service `git-probe`. The Deployment has `2` available replicas.

## Constraints

Create the project before the Application. Do not change the project `default` and do not add any other repository, destination or kind.

---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Scope An Ignore Difference Exception

The `git-probe` service on Starfleet station `outpost` is resized by a scaling controller during busy periods. Operations also want Argo CD to repair any other manual change to the service, such as a changed image. Today every resize shows as drift, and Argo CD scales the service back.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the path `plain` on the branch `main` with the Deployment and Service `git-probe` for the namespace `starfleet`. The Deployment declares two replicas. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-050-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-050-01-01`.

## Required result

- An Application `mission` in `argocd` uses the project `default`, the repository above, the revision `main` and the path `plain`, and deploys to the namespace `starfleet`.
- The Application has automated sync with `prune: true` and `selfHeal: true`, and it is `Synced` and `Healthy`.
- The Application has exactly one `ignoreDifferences` entry. It selects the group `apps` and the kind `Deployment` and ignores only the pointer `/spec/replicas`.
- A replica count that someone sets by hand stays in place and the Application stays `Synced`.
- A manual change of the container image is reverted by Argo CD, and the replica count that someone set by hand survives that repair.

## Constraints

- Do not ignore any other field and do not use a wildcard for the kind or the group.
- Do not depend on manual edits of the Deployment to pass. The grader changes the replica count and the image itself to test the behaviour.

---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Bring The Station Fleet Under Three Reconciliation Patterns

The station runs its services through Argo CD in three different ways. The service `ops-bridge` is scaled by an autoscaler that the station does not control, so Argo CD must leave its replica count alone and still repair every other change. The services `alpha` and `beta` must come from one parent Application, so that a new service needs only a new file. The probe service must run in three environments that are generated from data files in Git.

## Starting state

Argo CD, including the ApplicationSet controller, is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the paths `plain`, `apps` and `kustomize/base`, and the files `envs/dev/config.json`, `envs/staging/config.json` and `envs/prod/config.json` on the branch `main`. The path `apps` holds the Application manifests of `alpha` and `beta`. No Application or ApplicationSet exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-050)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-050`.

## Required result

- An Application `ops-bridge` uses the project `default`, the repository above, the revision `main` and the path `plain`, and deploys to the namespace `starfleet`. Its sync policy is automated with `prune: true` and `selfHeal: true`, and its sync options include `CreateNamespace=true` and `RespectIgnoreDifferences=true`. It has exactly one `ignoreDifferences` entry for the group `apps`, the kind `Deployment` and the pointer `/spec/replicas`. It is `Synced` and `Healthy`. A replica count that someone sets by hand on the Deployment `git-probe` stays and the Application stays `Synced`.
- An Application `fleet-root` uses the path `apps` of the revision `main` and deploys to the namespace `argocd`, with automated sync, prune and self-heal. It creates the Applications `alpha` and `beta`, owns them, and both become `Synced` and `Healthy`. If someone edits the revision of the live Application `alpha`, the parent sets it back to `main`. If someone deletes the live Application `beta`, the parent creates it again and the Deployment `beta` is not removed.
- An ApplicationSet `fleet-envs` uses a Git generator in files mode over `envs/*/config.json` and creates the Applications `probe-dev`, `probe-staging` and `probe-prod`. Each one deploys the path `kustomize/base` into the namespace `probe-` followed by the environment name, and each Deployment `git-probe` has the replica count of its file: 1, 2 and 3. If someone edits the revision of the live Application `probe-staging`, the ApplicationSet controller sets it back to `main`.

## Constraints

- Create only the Application `ops-bridge`, the Application `fleet-root` and the ApplicationSet `fleet-envs`. Argo CD creates every other Application.
- Do not hard-code environment names or replica counts in the template of the ApplicationSet.
- Do not ignore any field other than the replica count of Deployments, and only for `ops-bridge`.

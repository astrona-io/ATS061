---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Generate Environments With An ApplicationSet

The Starfleet probe service runs in three environments: `dev`, `staging` and `prod`. Each environment has a small data file in Git that names the environment and its replica count. The operations team wants one ApplicationSet that turns these files into three Applications, so that a new environment needs only a new file.

## Starting state

Argo CD, including the ApplicationSet controller, is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the files `envs/dev/config.json`, `envs/staging/config.json` and `envs/prod/config.json` on the branch `main`. Each file has the fields `environment` and `replicas`. The path `kustomize/base` holds the Deployment and Service `git-probe`. No Application or ApplicationSet exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-050-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-050-03-01`.

## Required result

- An ApplicationSet `fleet-envs` in `argocd` uses a Git generator in files mode with the path pattern `envs/*/config.json`, the repository above and the revision `main`.
- The ApplicationSet creates the Applications `probe-dev`, `probe-staging` and `probe-prod`. Each one deploys the path `kustomize/base` of the revision `main` with automated sync, prune and self-heal, into the namespace `probe-` followed by the environment name. The namespace is created by Argo CD.
- Each Application is `Synced` and `Healthy`, and the Deployment `git-probe` in its namespace has the replica count that the file of that environment names: 1 for `dev`, 2 for `staging` and 3 for `prod`.
- The generated Applications are owned by the ApplicationSet. If someone edits the revision of the live Application `probe-staging`, the ApplicationSet controller sets it back to `main`. If someone deletes the live Application `probe-dev`, the ApplicationSet controller creates it again.

## Constraints

- Do not create the Applications yourself. Only the ApplicationSet may create them.
- Do not hard-code environment names or replica counts in the template. Use the parameters of the files.

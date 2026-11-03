---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Sync An Ordered Application With Hooks And Options

The `wave-app` service of the fleet needs a configuration object first, a Deployment second, a Service last, a check job before the rollout and a notification job after it. The manifests are ready in Git with the correct waves and hooks. Create the Application that syncs them with the right sync options.

## Starting state

Argo CD is installed in the `argocd` namespace. The Git server at `http://git-source.argocd.svc:8080/repo.git` holds the path `waves` on the branch `main`. No Application exists.

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-020-02-01`.

## Required result

- An Application named `ordered` in the `argocd` namespace uses the project `default`, the repository above, the revision `main` and the path `waves`, and deploys to the namespace `starfleet` of `https://kubernetes.default.svc`.
- Its sync policy is automated with `prune: true`.
- Its sync options include `CreateNamespace=true` and `PruneLast=true`.
- The Application is `Synced` and `Healthy`. The ConfigMap `wave-config`, the Deployment `wave-app` and the Service `wave-app` exist in `starfleet`.
- The last operation succeeded and its result lists both a `PreSync` and a `PostSync` hook. The hook Jobs are deleted after they succeeded.

---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Playground: Waves, Hooks And Sync Options

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The path `waves` holds the ConfigMap `wave-config` (wave `-1`), the Deployment and Service `wave-app` (the Service is in wave `1`), the PreSync Job `wave-presync` and the PostSync Job `wave-postsync`. No Application exists and nothing is graded.

Connect to the cluster:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-020-02)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-020-02`.

## Things to try

Create an Application for the path `waves` with no sync policy. Sync it by hand while you watch the Jobs in `starfleet` with `kubectl -n starfleet get jobs --watch` in a second terminal. Read `status.operationState.syncResult.resources` to see the phase of each entry. Then add `CreateNamespace=true`, `PruneLast=true` and `ApplyOutOfSyncOnly=true` to `spec.syncPolicy.syncOptions` and sync again. Finally, point the Application at the path `broken/bad-image` and watch the Deployment stay in `Progressing` while the sync operation stays in `Running`.

## Common pitfalls

> [!WARNING]
> Hook Jobs with the delete policy `HookSucceeded` disappear after a successful sync. Watch the Jobs while the sync runs, or read the sync result afterwards, because a later `kubectl get jobs` shows nothing.

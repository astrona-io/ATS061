---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Playground: Retries, Sync Windows And Rollback

This environment is a `kind` cluster with Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The branch `main` and the branch `release` both hold the path `plain`, with two replicas on `main` and three on `release`. The path `broken/unknown-kind` holds an object that the cluster cannot create. No Application or project besides `default` exists and nothing is graded.

Connect to the cluster:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-020-03)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-020-03`.

## Things to try

Create an Application for `broken/unknown-kind` with `spec.syncPolicy.retry` and watch `status.operationState.retryCount`. Create an AppProject with a deny window that is always active (`schedule: '* * * * *'`, `duration: 24h`) and an Application in it with automated sync, and check that no operation starts. Change `manualSync` and see how the manual sync reacts. Sync an Application on `main`, then with `--revision release`, read `status.history`, turn automated sync off if it is on, and roll back with `argocd app rollback NAME ID --core`.

## Common pitfalls

> [!WARNING]
> The `argocd` command in core mode needs `--core` on every command and the namespace `argocd` in the `kubectl` context. Without them it tries to reach an Argo CD server that is not exposed.

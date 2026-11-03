---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Retry, Block And Roll Back A Sync In The Playground

The earlier parts described three controls: the retry policy, the sync window and the rollback. In this part you use each of them on a real Application in the playground and read the fields that prove what happened. You need a second terminal for the retry step. All commands run against the playground cluster, which has Argo CD and the Git server in the `argocd` namespace.

## Connect and prepare the command line

Connect to the playground cluster. The command line client `argocd` can talk to the Kubernetes API directly in core mode, without a login to the Argo CD server. Core mode reads the Application objects from the namespace that your `kubectl` context uses, so set that namespace first.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-020-03)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
argocd login --core
```

The context must be `kind-astro-ats-061-playground-020-03`. Every `argocd` command in this part carries the flag `--core`.

## Retry a sync that cannot succeed

The path `broken/unknown-kind` holds an object of the kind `Widget`, and the cluster has no definition for it. Every sync of this path fails. Save this Application as `application-broken.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: broken
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: broken/unknown-kind
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 2
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 1m
```

Apply it and read the operation while it retries:

```sh
kubectl apply -f application-broken.yaml
kubectl -n argocd get application broken -o jsonpath='{.status.operationState.phase}{" "}{.status.operationState.retryCount}{"\n"}'
```

Repeat the second command every few seconds. The phase starts as `Running` and the retry count rises. After the limit of 2 retries, with waits of 5 and 10 seconds, the phase becomes `Failed`. Read the reason of the failure in the sync result:

```sh
kubectl -n argocd get application broken -o jsonpath='{.status.operationState.message}{"\n"}'
```

The message names the failed resource. The retry did not help, because the manifest is wrong and not the timing. Delete the Application when you are done:

```sh
kubectl -n argocd delete application broken
```

## Block automated sync with a deny window

Create a project with a deny window that is always active. The cron expression `* * * * *` starts a window every minute and the duration `24h` keeps it active, so the window never ends. Save this as `project-maintenance.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: maintenance
  namespace: argocd
spec:
  sourceRepos:
  - '*'
  destinations:
  - server: https://kubernetes.default.svc
    namespace: '*'
  syncWindows:
  - kind: deny
    schedule: '* * * * *'
    duration: 24h
    applications:
    - '*'
    manualSync: true
```

Then save an Application in this project as `application-alpha.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: alpha
  namespace: argocd
spec:
  project: maintenance
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: workloads/alpha
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
    syncOptions:
    - CreateNamespace=true
```

Apply the project first and the Application second, then check what the controller did:

```sh
kubectl apply -f project-maintenance.yaml
kubectl apply -f application-alpha.yaml
argocd app get alpha --core
kubectl -n argocd get application alpha -o jsonpath='{.status.sync.status}{" "}{.status.operationState.phase}{"\n"}'
```

The sync status is `OutOfSync` and the operation phase is empty, because no operation started. The output of `argocd app get` shows that the window denies syncs. Automated sync is on, but the window blocks it. Start a manual sync, which the window allows because of `manualSync: true`:

```sh
argocd app sync alpha --core
```

The sync runs and the Application becomes `Synced`. The window blocked only the unattended start.

## Roll back to an earlier revision

Save an Application without automated sync as `application-release-train.yaml`. It uses the path `plain`, which has two replicas on `main` and three on `release`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: release-train
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: plain
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
```

Apply it, sync it on `main`, then sync it on the branch `release` and read the history:

```sh
kubectl apply -f application-release-train.yaml
argocd app sync release-train --core
argocd app sync release-train --revision release --core
argocd app history release-train --core
```

The history now has two entries. The first one is the revision of `main` and the second one is the revision of `release`. Read the replica count, roll back to the id of the first entry that the history printed, and read the replica count again:

```sh
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
argocd app rollback release-train ID --core
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

Replace `ID` with the id of the first entry. The count changes from 3 to 2. The Application is `OutOfSync`, because the target revision `main` has a different commit than the revision that the rollback applied. This is the state that the rollback leaves on purpose.

## What the part showed

You made a sync fail and saw that a retry repeats the failure when the manifest is wrong. You blocked an automated sync with a deny window and started it by hand with `manualSync`. You returned a workload to an earlier revision with a rollback and saw the Application `OutOfSync` afterwards.

## Common pitfalls

> [!WARNING]
> Create the project before the Application that uses it, otherwise the first automated sync can start before the window exists. Also, do not enable automated sync on `release-train` before the rollback, because Argo CD refuses a rollback while it is on.

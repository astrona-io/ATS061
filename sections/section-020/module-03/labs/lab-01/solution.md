---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Freeze Automated Syncs And Roll Back A Release Solution

Connect to the lab cluster and prepare the `argocd` command line client for core mode:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-03-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
argocd login --core
```

## Create the project and the frozen Application

Create the project first, so the window exists before the Application can sync. Save this as `project-maintenance.yaml`:

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

Save this as `application-frozen.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frozen
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
    retry:
      limit: 3
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 2m
```

Apply both in this order:

```sh
kubectl apply -f project-maintenance.yaml
kubectl apply -f application-frozen.yaml
```

Then check the result:

```sh
kubectl -n argocd get application frozen -o jsonpath='{.status.sync.status}{" "}{.status.operationState.phase}{"\n"}'
kubectl -n starfleet get deployment alpha
```

The sync status should be `OutOfSync`, the phase should be empty and the Deployment should not exist. Run `astrona submit` to check this step.

## Deploy release-train from two revisions

Save this as `application-release-train.yaml`:

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

Apply it, sync it on `main`, then on `release`, and read the history:

```sh
kubectl apply -f application-release-train.yaml
argocd app sync release-train --core
argocd app sync release-train --revision release --core
argocd app history release-train --core
```

The history should list two entries. Run `astrona submit` again.

## Roll back

Roll back to the id of the first entry and check the replica count:

```sh
argocd app rollback release-train ID --core
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

Replace `ID` with the id of the first history entry. The count should be `2` and the Application should be `OutOfSync`. Run `astrona submit` once more.

After recording your result, remove the lab with `astrona destroy ats-061-lab-020-03-01`.

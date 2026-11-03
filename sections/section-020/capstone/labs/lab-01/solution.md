---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Run A Controlled Release Of The Fleet Solution

Connect to the lab cluster and prepare the `argocd` command line client for core mode:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-020)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
argocd login --core
```

## Deploy main-deck with order, hooks and self healing

The waves and hooks are already annotated in Git. The Application adds automation with pruning and self healing, and the options for the namespace and for a late prune. Save this as `application-main-deck.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: main-deck
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: waves
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - PruneLast=true
```

Apply it and wait for it:

```sh
kubectl apply -f application-main-deck.yaml
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/main-deck --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/main-deck --timeout=240s
```

Test the self healing by changing the Deployment by hand, then read it again after a few seconds:

```sh
kubectl -n starfleet scale deployment wave-app --replicas=3
kubectl -n starfleet get deployment wave-app -o jsonpath='{.spec.replicas}{"\n"}'
```

The count returns to `1`. Run `astrona submit` to check this step.

## Freeze cargo-bay

Create the project first. Save this as `project-freeze.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: freeze
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

Save the Application as `application-cargo-bay.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cargo-bay
  namespace: argocd
spec:
  project: freeze
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: workloads/beta
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

Apply them in this order and check that nothing synced:

```sh
kubectl apply -f project-freeze.yaml
kubectl apply -f application-cargo-bay.yaml
kubectl -n argocd get application cargo-bay -o jsonpath='{.status.sync.status}{" "}{.status.operationState.phase}{"\n"}'
```

The status should be `OutOfSync` with an empty phase. Run `astrona submit` again.

## Roll back fleet-release

Save this as `application-fleet-release.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fleet-release
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

Apply it, sync `main` and then `release`, and read the history:

```sh
kubectl apply -f application-fleet-release.yaml
argocd app sync fleet-release --core
argocd app sync fleet-release --revision release --core
argocd app history fleet-release --core
```

Roll back to the id of the first entry and check the replicas:

```sh
argocd app rollback fleet-release ID --core
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

Replace `ID` with the first id. The count should be `2`. Run `astrona submit` for the final check.

After recording your result, remove the lab with `astrona destroy ats-061-capstone-020`.

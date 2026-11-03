---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Bring The Station Fleet Under Three Reconciliation Patterns Solution

Connect to the lab cluster and select the namespace `argocd`:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-050)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

## Create ops-bridge with an ignore rule for the replica count

The autoscaler owns the replica count, so the Application ignores that one field. The sync option `RespectIgnoreDifferences=true` makes sure a sync that repairs another field does not write the Git value back into the replica count. Save this as `application-ops-bridge.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ops-bridge
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
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

Apply it:

```sh
kubectl apply -f application-ops-bridge.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/ops-bridge --timeout=300s
kubectl -n starfleet scale deployment git-probe --replicas=4
kubectl -n argocd get application ops-bridge
```

The Application stays `Synced` and the Deployment keeps 4 replicas. Run `astrona submit` to check this step. The grader scales the Deployment itself, so you can scale it back to 2 afterwards if you want a clean state.

## Create the parent Application

The parent reads the path `apps`, where the child Application manifests live. Its destination namespace is `argocd`, because the children are Application objects and Application objects live in that namespace. Save this as `application-fleet-root.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fleet-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply it:

```sh
kubectl apply -f application-fleet-root.yaml
```

Then check the result:

```sh
kubectl -n argocd get applications
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/alpha --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/beta --timeout=300s
kubectl -n argocd get application alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
```

The list shows `fleet-root`, `alpha`, `beta` and `ops-bridge`. The tracking annotation of `alpha` starts with `fleet-root:`. Run `astrona submit` again.

## Create the ApplicationSet

The three environments must not share one namespace, because the base manifests use the same object names. The template therefore sets the Kustomize namespace and the Kustomize replica count from the parameters of the data files. Save this as `applicationset-fleet-envs.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: fleet-envs
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - git:
      repoURL: http://git-source.argocd.svc:8080/repo.git
      revision: main
      files:
      - path: 'envs/*/config.json'
  template:
    metadata:
      name: 'probe-{{ .environment }}'
    spec:
      project: default
      source:
        repoURL: http://git-source.argocd.svc:8080/repo.git
        targetRevision: main
        path: kustomize/base
        kustomize:
          namespace: 'probe-{{ .environment }}'
          replicas:
          - name: git-probe
            count: '{{ .replicas }}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'probe-{{ .environment }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

Apply it:

```sh
kubectl apply -f applicationset-fleet-envs.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-prod --timeout=300s
kubectl -n probe-dev get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n probe-staging get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n probe-prod get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

The counts are 1, 2 and 3. Run `astrona submit` once more. The grader edits `alpha` and `probe-staging` and deletes `beta`, and then waits up to 90 seconds for each repair.

After recording your result, remove the lab with `astrona destroy ats-061-capstone-050`.

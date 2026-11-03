---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Edit, Delete And Diagnose Child Applications In The Playground

A parent Application makes a promise: the child Applications in Git are the child Applications in the cluster. In this part you test that promise. You edit a child by hand, delete a child and read what the parent does. Then you point a parent at a path that does not exist and learn to find the layer that failed. All commands run against the playground cluster, which has Argo CD and the Git server in the namespace `argocd`.

## Connect and create the parent

Connect to the playground and select the namespace `argocd`:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-050-02)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

Save this parent Application as `application-fleet-root.yaml`. It reads the path `apps`, which holds the manifests of the children `alpha` and `beta`:

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
    syncOptions:
    - CreateNamespace=true
```

Apply it and wait until the parent and both children are healthy:

```sh
kubectl apply -f application-fleet-root.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/fleet-root --timeout=300s
kubectl -n argocd get applications
```

The list shows `fleet-root`, `alpha` and `beta`, each `Synced` and `Healthy`. The Deployments `alpha` and `beta` exist in the namespace `starfleet`.

## Edit a child by hand

Change the revision of the child `alpha` in the live object. The tag `v1.0.0` points to the same commit as `main`, so the workload stays the same, and the change touches only the child object:

```sh
kubectl -n argocd patch application alpha --type merge -p '{"spec":{"source":{"targetRevision":"v1.0.0"}}}'
kubectl -n argocd get application alpha -o jsonpath='{.spec.source.targetRevision}{"\n"}'
```

The first read may show `v1.0.0`. Run the second command again after about 15 seconds. The value is `main` again. The parent compared its target state, which holds `main`, with the live child, found a difference in the child object, and self-heal applied the parent manifest again. The child did not repair itself, because the child compares its workloads, not its own manifest.

## Delete a child

Delete the child `beta` and read the Applications and the Deployment right after:

```sh
kubectl -n argocd delete application beta
kubectl -n argocd get applications
kubectl -n starfleet get deployment beta
```

Two things happen. The Application `beta` disappears and comes back within a few seconds, created again by the parent. The Deployment `beta` is not touched in between, because the child manifest has no finalizer, so deleting the Application object does not delete the workloads. The age of the new Application object is a few seconds, and the Deployment has the old age.

## Remove the parent and keep the children

The parent has no finalizer either. Delete it and list the Applications:

```sh
kubectl -n argocd delete application fleet-root
kubectl -n argocd get applications
```

Both children are still there and still synced. The parent is gone, so nothing owns the child Application objects any more and nothing repairs them. A parent with the finalizer `resources-finalizer.argocd.argoproj.io` would have removed its resources first, which are the two child Application objects.

## Read a failing parent

Delete the children and the workloads to start clean, and create a parent with a wrong path. Save this as `application-lost-root.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lost-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: appz
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
```

Apply it and read the conditions of the Application:

```sh
kubectl -n argocd delete application alpha beta
kubectl -n starfleet delete deployment,service alpha beta
kubectl apply -f application-lost-root.yaml
kubectl -n argocd get application lost-root -o jsonpath='{.status.conditions[0].type}{" "}{.status.conditions[0].message}{"\n"}'
```

The condition type is `ComparisonError`, and the message names the path `appz` that the repository server could not find. No child was created, and no workload exists. This is the first failed layer: the parent could not render its source. Fixing a child, a Deployment or the cluster would change nothing.

## Find the failing layer

Read an app-of-apps problem from the top down. First list the Applications. If a child is missing, read the parent: its status, its conditions and the resources in `argocd app get`. If the child exists but is `OutOfSync` or shows `ComparisonError`, read the child, because the failure is in its own source or destination. If the child is `Synced` but `Degraded`, read its workloads, for example with `kubectl describe`. Each layer has its own status, and the status of a layer tells you whether to look one level lower.

## What the part showed

The parent repairs edits of the child objects it owns and creates a deleted child again, and it leaves the workloads alone unless a finalizer asks for a cascade. Removing the parent without a finalizer leaves the children without an owner. A parent that cannot render its path reports a comparison error and creates nothing, so the fault is at the top layer.

## Common pitfalls

> [!WARNING]
> Do not edit a child Application by hand when the parent runs with self-heal. The parent reverts the edit within seconds, so change the manifest in Git instead. Also, deleting a child or a parent without the finalizer leaves the workloads running. Check the Deployments before you assume that the delete removed them.

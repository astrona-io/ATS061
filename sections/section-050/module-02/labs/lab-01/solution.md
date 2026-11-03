---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Bootstrap The Fleet With An App Of Apps Solution

Connect to the lab cluster and select the namespace `argocd`:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-050-02-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

## Create the parent

The parent reads the path `apps`, which holds the child manifests. Its destination namespace is `argocd`, because the children are Application objects. Self-heal makes the parent repair edits of the children. Save this as `application-fleet-root.yaml`:

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

Apply it:

```sh
kubectl apply -f application-fleet-root.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/fleet-root --timeout=300s
kubectl -n argocd get applications
kubectl -n starfleet get deployments
```

The list shows `fleet-root`, `alpha` and `beta`, all `Synced` and `Healthy`, and the namespace `starfleet` holds the Deployments `alpha` and `beta`. Run `astrona submit` to check this step.

## Test the repair

The grader edits and deletes children itself, and you can do the same to see the result. Change the revision of `alpha` and delete `beta`:

```sh
kubectl -n argocd patch application alpha --type merge -p '{"spec":{"source":{"targetRevision":"v1.0.0"}}}'
kubectl -n argocd delete application beta
```

Wait about 20 seconds and read the objects again:

```sh
kubectl -n argocd get application alpha -o jsonpath='{.spec.source.targetRevision}{"\n"}'
kubectl -n argocd get applications
kubectl -n starfleet get deployment beta
```

The revision of `alpha` is `main`, the Application `beta` exists again and the Deployment `beta` kept running. Run `astrona submit` once more.

After recording your result, remove the lab with `astrona destroy ats-061-lab-050-02-01`.

---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Sync An Ordered Application With Hooks And Options Solution

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-02-01)"
kubectl config current-context
```

## Write the Application

The hooks and waves are already annotated in Git, so the Application only needs the source, the policy and the options. Automation with `prune: true` starts the sync by itself. `CreateNamespace=true` makes sure the destination namespace exists, and `PruneLast=true` moves pruning after the other objects. Save this as `application-ordered.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ordered
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
    syncOptions:
    - CreateNamespace=true
    - PruneLast=true
```

Apply it:

```sh
kubectl apply -f application-ordered.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/ordered --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/ordered --timeout=240s
kubectl -n argocd get application ordered -o jsonpath='{.status.operationState.phase}'
```

The operation phase should be `Succeeded`. Run `astrona submit` to check this step.

## Read the hook evidence

The hook Jobs are deleted after they succeed, so the evidence is in the sync result:

```sh
kubectl -n argocd get application ordered -o jsonpath='{range .status.operationState.syncResult.resources[*]}{.kind}{" "}{.name}{" "}{.syncPhase}{"\n"}{end}'
kubectl -n starfleet get jobs
```

The first command should list a `PreSync` and a `PostSync` entry. The second should show no `wave-presync` or `wave-postsync` Job. Run `astrona submit` again.

After recording your result, remove the lab with `astrona destroy ats-061-lab-020-02-01`.

---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Repair Live Drift With Self Healing Solution

Connect to the lab cluster:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-020-01-01)"
kubectl config current-context
```

## Create the Application with automation

An Application without a sync policy only compares. The policy `automated` makes the controller sync on its own, `prune` lets it delete objects that Git dropped, and `selfHeal` lets it revert live changes. Save this as `application-mission.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mission
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
```

Apply it:

```sh
kubectl apply -f application-mission.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s
```

Run `astrona submit` to check this step.

## Prove self-heal

Scale the Deployment down and wait for Argo CD to restore it:

```sh
kubectl -n starfleet scale deployment/git-probe --replicas=1
kubectl -n starfleet wait --for=jsonpath='{.spec.replicas}'=2 deployment/git-probe --timeout=180s
```

If the wait ends successfully, self-heal works. Run `astrona submit` again.

After recording your result, remove the lab with `astrona destroy ats-061-lab-020-01-01`.

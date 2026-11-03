---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Scope An Ignore Difference Exception Solution

Connect to the lab cluster and select the namespace `argocd`:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-050-01-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

## Create the Application

The task needs three settings: automated sync with self-heal, an ignore rule for the replica count and the sync option that makes a sync respect the rule. Save this as `application-mission.yaml`:

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
kubectl apply -f application-mission.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s
```

Both commands return when the Application is `Synced` and `Healthy`. Run `astrona submit` to check this step. The checks that change the replica count and the image run in the same submission, and they change the live Deployment themselves.

## Test the behaviour yourself

You may repeat what the grader does. Scale the Deployment and wait about 30 seconds:

```sh
kubectl -n starfleet scale deployment git-probe --replicas=4
kubectl -n argocd get application mission -o jsonpath='{.status.sync.status}{"\n"}'
```

The status stays `Synced` and the Deployment keeps 4 replicas. Change the image and read both values after about 20 seconds:

```sh
kubectl -n starfleet set image deployment/git-probe git-probe=docker.io/library/python:3.12-alpine
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The image is back to `python:3.13-alpine` and the count is still 4. Run `astrona submit` once more.

After recording your result, remove the lab with `astrona destroy ats-061-lab-050-01-01`.

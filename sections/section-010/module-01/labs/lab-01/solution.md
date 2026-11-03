---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Deliver A Git Sourced Application With Argo CD Solution

This walkthrough creates the Application, waits for the two statuses and proves that self-healing works.

## Step 1: Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-010-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-010-01-01`.

## Step 2: Inspect the starting state

```sh
kubectl -n argocd get pods
kubectl -n argocd get applications
kubectl -n starfleet get deployments
```

The Argo CD pods run, no Application exists and `starfleet` has no `git-probe`.

## Step 3: Create the Application

Save this as `application-mission.yaml`:

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
kubectl -n argocd get application mission -o jsonpath='{.status.sync.revision}{"\n"}'
kubectl -n starfleet get deployment git-probe
```

The repository server rendered the `plain` directory, the application controller applied it and the Deployment reports 2 ready replicas. Run `astrona submit` now to check the Application source, the two statuses, the tracked Deployment and the self-healing test.

## Step 4: Prove self-healing

The grader scales the Deployment to 4 replicas and expects Argo CD to put it back to 2. You can try the same change first:

```sh
kubectl -n starfleet scale deployment git-probe --replicas=4
kubectl -n starfleet wait --for=jsonpath='{.spec.replicas}'=2 deployment/git-probe --timeout=120s
```

The application controller sees the live change, marks the Application `OutOfSync` and, because `selfHeal` is `true`, syncs it again.

After recording your result, remove the lab with `astrona destroy ats-061-lab-010-01-01`.

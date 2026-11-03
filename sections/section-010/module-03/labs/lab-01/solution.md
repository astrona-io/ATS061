---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Correct An OutOfSync And Unhealthy Application Solution

This walkthrough reads the two status fields, finds the cause of each problem and then changes the Application.

## Step 1: Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-010-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-010-03-01`.

## Step 2: Read the sync status and the health status

Read the two statuses and the resources the Application owns:

```sh
kubectl -n argocd get application bridge-cam
kubectl -n argocd get application bridge-cam -o jsonpath='{range .status.resources[*]}{.kind}{" "}{.name}{" sync="}{.status}{" health="}{.health.status}{"\n"}{end}'
kubectl -n starfleet get pods
```

The sync status says whether live matches Git, and the health status says whether the resources work. The `bad-image` Deployment is the unhealthy resource: its pod shows `ImagePullBackOff` or `ErrImagePull`. The Deployment reports `Progressing` first and `Degraded` after its progress deadline of 600 seconds passes, so the Application health status can be either.

## Step 3: Point the Application at the corrected workload

Save this as `application-bridge-cam.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bridge-cam
  namespace: argocd
spec:
  project: default
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
      selfHeal: false
```

The path now selects the corrected workload. The setting `prune: true` lets automated sync delete live resources that are no longer in the source. Without it, the `bad-image` Deployment would stay and the Application would stay `OutOfSync`.

Apply it:

```sh
kubectl apply -f application-bridge-cam.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/bridge-cam --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/bridge-cam --timeout=240s
kubectl -n starfleet get deployments
```

The list shows `beta` and no `bad-image`.

Run `astrona submit` now. All four checks must pass: the compared path, the delivered `beta` Deployment, the removed `bad-image` Deployment and the Synced and Healthy Application.

After recording your result, remove the lab with `astrona destroy ats-061-lab-010-03-01`.

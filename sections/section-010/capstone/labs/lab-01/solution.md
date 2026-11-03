---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Repair, Create And Report On Argo CD Applications Solution

This walkthrough repairs the two Applications, creates the third one and then reads the report values from the cluster.

## Step 1: Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-010)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-010`.

## Step 2: Read the state of all Applications

```sh
kubectl -n argocd get applications
kubectl -n argocd get application flight-deck -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
kubectl -n starfleet get pods
```

`flight-deck` has a `ComparisonError` condition: its path `plian` does not exist, and the repository server cannot render it. `hangar-cam` is synced with a Deployment whose pod cannot pull its image.

## Step 3: Repair the two Applications and create the third

Save this as `applications.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: flight-deck
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
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hangar-cam
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
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mission-log
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: workloads/gamma
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

The first Application gets the correct path. The second gets the corrected workload path and `prune: true`, so Argo CD removes `bad-image`. The third is new.

Apply it:

```sh
kubectl apply -f applications.yaml
```

Then check the result:

```sh
kubectl -n argocd get applications
kubectl -n starfleet get deployments
```

Wait until all three Applications show `Synced` and `Healthy`. If one stays `Unknown`, run a hard refresh on it with `kubectl -n argocd annotate application <name> argocd.argoproj.io/refresh=hard --overwrite`.

## Step 4: Write the status report

Read the three values from the cluster:

```sh
kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-repo-server -o jsonpath='{.items[0].metadata.name}{"\n"}'
kubectl -n argocd get statefulset,deployment
kubectl -n argocd get application flight-deck -o jsonpath='{.status.sync.revision}{"\n"}'
```

The application controller appears under `statefulset`, so its kind is `StatefulSet`. Create the ConfigMap with the values you read. Replace the two placeholders:

```sh
kubectl -n argocd create configmap status-report --from-literal=repo-server-pod=<REPO_SERVER_POD> --from-literal=controller-kind=StatefulSet --from-literal=flight-deck-revision=<REVISION>
```

Run `astrona submit` now. All four checks must pass: `flight-deck`, `hangar-cam`, `mission-log` and `status-report`.

After recording your result, remove the lab with `astrona destroy ats-061-capstone-010`.

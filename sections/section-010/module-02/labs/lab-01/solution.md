---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Repair An Application With A Comparison Error Solution

This walkthrough reads the error first, fixes the two source fields and then proves that Argo CD delivers the workload.

## Step 1: Connect to the lab

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-010-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-010-02-01`.

## Step 2: Read the Application status

Read the sync status and the conditions of the Application:

```sh
kubectl -n argocd get application fleet-registry
kubectl -n argocd get application fleet-registry -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
```

The sync status is `Unknown`. A condition of type `ComparisonError` names the problem: the repository server could not use the revision or the path. The Application reads the revision `v9.9.9` and the path `plain-manifests`, and neither exists in the repository. The repository server is the component that checks out a revision and renders a path, so the error comes from there.

Confirm it in the repository server log:

```sh
kubectl -n argocd logs deployment/argocd-repo-server --tail=30
```

The log lines name the revision or the path that failed.

## Step 3: Correct the source

Save this as `application-fleet-registry.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fleet-registry
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: v1.0.0
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
kubectl apply -f application-fleet-registry.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/fleet-registry --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/fleet-registry --timeout=240s
kubectl -n argocd get application fleet-registry -o jsonpath='{.status.sync.revision}{"\n"}'
kubectl -n starfleet get deployment git-probe
```

If the sync status stays `Unknown`, ask for a hard refresh, which also clears the cached manifests:

```sh
kubectl -n argocd annotate application fleet-registry argocd.argoproj.io/refresh=hard --overwrite
```

Run `astrona submit` now. All four checks must pass: the source location, the cleared comparison error, the resolved revision and the delivered workload.

After recording your result, remove the lab with `astrona destroy ats-061-lab-010-02-01`.

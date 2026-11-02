---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Constrain Application Source And Destination Solution

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-061-lab-030-01-01" || exit 1
node_name="astro-ats-061-lab-030-01-01-control-plane"
worker_name="astro-ats-061-lab-030-01-01-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Inspect And Explain

Argo CD controllers are installed in argocd. The task uses a disposable internal Git source. No learner Application exists.

Inspect the current objects before changing them:

```sh
kubectl -n starfleet get pods -o wide
kubectl get nodes -o wide
```

Allow only the private repository, starfleet destination, Deployment and Service resources in an AppProject. The Application must sync successfully inside that boundary.

Save this as `appproject-mission.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: mission
  namespace: argocd
spec:
  sourceRepos:
  - http://git-source.argocd.svc:8080/repo.git
  destinations:
  - server: https://kubernetes.default.svc
    namespace: starfleet
  namespaceResourceWhitelist:
  - group: apps
    kind: Deployment
  - group: ''
    kind: Service
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mission
  namespace: argocd
spec:
  project: mission
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

Apply the scoped correction:

```sh
kubectl apply -f appproject-mission.yaml
```

## Verify The Result

Observe the actual result. A denied request returns a nonzero status when the denial works, so run it separately from a shell sequence that stops on error. Status convergence and a successful request establish different parts of the result.

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s
```

Reconcile the declared application from the internal Git source. The commands above deliberately target one environment. Keep its remaining components available so an unrelated failure cannot stand in for the required denial or correction. No example command output is presented as evidence of a completed run. A matching field alone does not establish that a process used it or that a controller reconciled it.

After recording your result, remove the independent lab with `astrona destroy ats-061-lab-030-01-01`.

## Common pitfalls

> [!WARNING]
> Confirm the private context and exact node names before a change. Check the stated scope and live result. Do not change unrelated components to hide the original fault.

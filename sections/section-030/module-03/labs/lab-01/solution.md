---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Build An App Of Apps And Retire A Scratch Application Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-030-03-01`.

## Create the parent Application

The parent syncs the path `apps` into the namespace `argocd`, where the child Applications live. Save this as `application-fleet.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fleet
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
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
```

Apply it:

```sh
kubectl apply -f application-fleet.yaml
```

Then check the result. Wait for the children and read the markers:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/alpha --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/beta --timeout=240s
kubectl -n argocd get applications -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
kubectl -n argocd get application alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
```

The list should show `fleet`, `alpha`, `beta` and `scratch`. The annotation should name `fleet` as the owner of the Application `alpha`. Run `astrona submit` to check this step. It reports `scratch` as still present, which is expected.

## Retire the scratch Application

The Application `scratch` has the cascading finalizer, so deleting it also deletes its Deployment. Delete only the Application:

```sh
kubectl -n argocd delete application scratch
kubectl -n starfleet get deployment gamma
```

The `delete` command waits until the finalizer has run. The second command should answer that the Deployment `gamma` is not found. Run `astrona submit` for the last time.

After recording your result, remove the lab with `astrona destroy ats-061-lab-030-03-01`.

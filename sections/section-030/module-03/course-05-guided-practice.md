---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Build An App Of Apps And Delete It In The Playground

Tracking, finalizers, app-of-apps and health describe one chain of ownership, and the chain is easiest to understand when you walk it from the top. This practice creates a parent Application, reads the markers it leaves on the children and on their workloads, scales a workload by hand to see the tracking at work, and then deletes the parent in a way that removes the whole tree. The playground has Argo CD, the Git server at `http://git-source.argocd.svc:8080/repo.git` and no Application.

## Connect to the playground

Point `kubectl` at the playground cluster and check the context:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-030-03)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-030-03`.

## Create the parent

The path `apps` holds the manifests of the child Applications `alpha` and `beta`. Save this as `application-drill-fleet.yaml`. The parent has automated sync, prune and the cascading finalizer:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: drill-fleet
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
kubectl apply -f application-drill-fleet.yaml
```

Then check the result. Wait for the children and list the three Applications with their sync status and health:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/alpha --timeout=240s
kubectl -n argocd get applications -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
```

The list should show `drill-fleet`, `alpha` and `beta`, all `Synced` and `Healthy`. The child Applications came from Git, not from you, and the parent created them.

## Read the chain of markers

Each level carries a tracking annotation that names its owner. Read the annotation of the child Application and of the workload it deploys:

```sh
kubectl -n argocd get application alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
kubectl -n starfleet get deployment alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
```

The first line should name `drill-fleet` as the owner of the Application `alpha`. The second should name `alpha` as the owner of the Deployment `alpha`. The parent never touches the Deployment: its owner is the child.

## Let a child repair its workload

The child `alpha` has `selfHeal`. Scale its Deployment by hand and watch the child restore it:

```sh
kubectl -n starfleet scale deployment alpha --replicas=4
kubectl -n starfleet get deployment alpha -o jsonpath='{.spec.replicas}{"\n"}'
```

After a few seconds the count should return to `1`, set back by the child Application `alpha`, not by the parent. Try the same on the Application object: change `spec.source.targetRevision` of `alpha` to `release` with `kubectl patch`, and see the parent set it back, because the parent's `selfHeal` compares the child Application with Git.

## Delete the whole tree

Delete the parent. The finalizer makes the controller delete the child Applications first. The child manifests in Git have no finalizer of their own, so the children leave their Deployments in the cluster:

```sh
kubectl -n argocd delete application drill-fleet
kubectl -n argocd get applications
kubectl -n starfleet get deployments
```

The Application list should be empty, and the Deployments `alpha` and `beta` should still exist. They carry their tracking annotations, but no Application manages them. Add the finalizer to a child manifest (a copy of it as a new Application of your own) and repeat to see the Deployment disappear with the child.

## Ideas to try on your own

Create an Application for `broken/bad-image`, read its `Progressing` health and the pod events, and wait for the progress deadline. Create two Applications on `workloads/gamma` and read `status.conditions` for a shared resource warning. Create the parent without automated sync and see what its children show.

## What you saw

You saw a parent create child Applications from Git, you read the tracking annotations at both levels, you saw each Application repair its own objects and you saw that a finalizer on the parent removes the children but not their workloads.

## Common pitfalls

> [!WARNING]
> Deleting the parent with its finalizer removes the child Applications, not necessarily their workloads. The children must have a finalizer too. Leftover Deployments from an earlier step can conflict with a later one, so list the Deployments in `starfleet` before you start a new exercise.

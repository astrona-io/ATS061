---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Reconcile A Git Sourced Application In The Playground

Reading about the loop is not the same as watching it. In this part you create an Application, watch it move from `OutOfSync` to `Synced`, change the cluster by hand to cause drift, and then let automated sync with self-healing repair it. You use only `kubectl`, because an Application is a Kubernetes object.

## Connect to the playground

A kubeconfig is the file that tells `kubectl` which cluster and credentials to use. Point `kubectl` at the playground cluster and confirm the context:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-010-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-010-01`. Every command below runs against this cluster only.

## Look at what is installed

Argo CD runs as ordinary workloads in the `argocd` namespace. List them and the Applications:

```sh
kubectl -n argocd get pods
kubectl -n argocd get applications
```

You should see pods for `argocd-server`, `argocd-repo-server`, `argocd-redis`, `argocd-applicationset-controller` and `argocd-application-controller`, plus the `git-source` pod that serves the repository. The Dex server and the notifications controller are scaled to zero in this environment because nothing here needs them. The Application list is empty.

## Create an Application with manual sync

An Application without a `syncPolicy` never syncs by itself. That is the clearest way to see the two states before and after a sync.

Save this as `application-plain-demo.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: plain-demo
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
```

Apply it:

```sh
kubectl apply -f application-plain-demo.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=OutOfSync application/plain-demo --timeout=120s
kubectl -n argocd get application plain-demo
kubectl -n starfleet get deployments
```

The Application list shows the sync status `OutOfSync` among its columns, and the health status `Missing`, because none of its resources exist yet. The `starfleet` namespace has no `git-probe` Deployment. Argo CD has rendered the `plain` directory and compared it with an empty namespace, and it waits for you to start a sync.

## Start a sync and read the result

A sync is an operation. You start it by adding an `operation` field to the Application. The application controller sees the field, runs the sync and records the outcome in `status.operationState`.

```sh
kubectl -n argocd patch application plain-demo --type merge -p '{"operation":{"sync":{}}}'
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/plain-demo --timeout=180s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/plain-demo --timeout=180s
```

The first wait ends when the controller has applied the manifests. The second ends when the two `git-probe` replicas are available. Read what the controller recorded:

```sh
kubectl -n argocd get application plain-demo -o jsonpath='{.status.sync.revision}{"\n"}{.status.operationState.phase}{"\n"}'
kubectl -n starfleet get deployment git-probe -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
```

The first command prints two lines. The first line is the 40 character commit hash that Argo CD resolved from `main`. The second line is the phase of the sync operation, `Succeeded`. The second command prints the tracking annotation. It starts with `plain-demo:`, followed by the group and kind of the resource, its namespace and its name. This annotation tells Argo CD that the Deployment belongs to this Application.

## Cause drift by hand

Scale the Deployment directly with `kubectl`, which bypasses Git, and watch the Application react:

```sh
kubectl -n starfleet scale deployment git-probe --replicas=5
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=OutOfSync application/plain-demo --timeout=120s
```

The application controller watches the live Deployment, notices that `spec.replicas` is 5 where the source says 2, and sets the sync status to `OutOfSync`. The Deployment itself keeps running with 5 replicas: without automated sync, Argo CD only reports the drift. The health status can stay `Healthy`, because five available replicas are healthy. This is the combination `OutOfSync` and `Healthy`.

## Turn on automated sync with self-healing

Now let the controller fix the drift itself. Patching the Application changes its policy:

```sh
kubectl -n argocd patch application plain-demo --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
kubectl -n starfleet wait --for=jsonpath='{.spec.replicas}'=2 deployment/git-probe --timeout=180s
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/plain-demo --timeout=120s
```

As soon as automated sync is on, the controller finds an `OutOfSync` Application and starts a sync. The replicas return to 2 and the sync status returns to `Synced`. Repeat the `kubectl scale` command from the previous step with `--replicas=5` and the same wait on `.spec.replicas`: this time the controller repairs the change without any action from you.

You have now seen every state of the loop. A new Application was `OutOfSync` and `Missing`, a sync made it `Synced` and `Healthy`, a manual change made it `OutOfSync` again, and self-healing restored it. In each case a different component did the work: the repository server rendered, the application controller compared and applied, and the Kubernetes API server stored the result.

Before you leave, make sure you can answer one question without looking: which field would you read to know whether a sync operation succeeded, and which one to know whether the workload works? The answers are `status.operationState.phase` and `status.health.status`.

## Common pitfalls

> [!WARNING]
> Do not expect the cluster to change after you create an Application without a sync policy: it stays `OutOfSync` until a sync runs. If you scale a Deployment and nothing reverts it, the Application has no `selfHeal`. If the `operation` patch does nothing, an earlier operation may still be running. Wait for the previous operation to finish, then patch again.

---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Read And Correct Application Status With kubectl And The argocd CLI

The status fields are only useful if you can read them quickly under pressure. Two tools do it. `kubectl` shows the raw Application object. The `argocd` command-line client formats it as a table, shows the resource tree and prints a diff between the live state and the target state. This part uses both in the playground, on an Application that is in a bad state on purpose.

## The argocd client in core mode

The `argocd` client normally talks to the Argo CD API server and needs a login. **Core mode** removes that need. With the global flag `--core`, the client reads and writes Argo CD's Kubernetes objects directly through your kubeconfig. It starts a local API server process for each command and stops it when the command ends. Access follows Kubernetes RBAC only: you need permission on the Application objects in the `argocd` namespace, and Argo CD's own roles do not apply. The API server of the installation does not take part, so the web interface is not needed either.

Core mode finds Argo CD through the namespace of your current kubectl context. Set that namespace once:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-010-03)"
kubectl config set-context --current --namespace=argocd
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-010-03`. From now on `argocd ... --core` works against this cluster.

## An Application in a bad state

Argo CD cannot deliver a working application from a manifest that cannot run. The repository has a directory `broken/bad-image` with a Deployment named `bad-image` whose image tag does not exist. Create an Application for it with automated sync but without pruning or self-healing.

Save this as `application-status-demo.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: status-demo
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: broken/bad-image
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
```

Apply it:

```sh
kubectl apply -f application-status-demo.yaml
```

Then list the Applications and read this one:

```sh
argocd app list --core
argocd app get status-demo --core
```

The list shows one row for `status-demo` with its sync status, its health status, the repository, the path and the revision. The sync status becomes `Synced` after the automated sync, because Argo CD applied exactly what Git declares. The health status is `Progressing` first. The `get` output has the Application header with its project, destination and source, then a table of its resources with a sync column and a health column. The row for the `bad-image` Deployment is the unhealthy one. After the Deployment's progress deadline of 600 seconds passes, its health becomes `Degraded` and so does the Application's. The pod shows the reason:

```sh
kubectl -n starfleet get pods
```

The pod status is `ErrImagePull` or `ImagePullBackOff`. Argo CD reports that the resource is unhealthy, while Kubernetes explains why: it cannot pull the image. The two tools complement each other.

## Read a difference with argocd app diff

Make the Application `OutOfSync` by changing the live Deployment by hand, then ask for the difference:

```sh
kubectl -n starfleet scale deployment bad-image --replicas=2
argocd app diff status-demo --core
```

The command prints the differences between the live state and the target state in the style of a unified diff, one block per resource. You should see the `replicas` field with the value 2 in the live version and 1 in the target version. The exit code of `argocd app diff` is 0 when nothing differs, 1 when something does and 2 on an error. Scripts can test it. The flag `--exit-code=false` turns the 1 into a 0.

Because `selfHeal` is `false`, the controller leaves the change in place, and the sync status stays `OutOfSync` until a sync runs.

## Refresh and hard refresh from the client

Both refreshes are options of `argocd app get`:

```sh
argocd app get status-demo --refresh --core
argocd app get status-demo --hard-refresh --core
```

The first option makes the controller compare again with its caches. The second also discards the cached manifests, so the repository server clones and renders the source again. The result is the same in a healthy installation. You choose the hard refresh when you suspect that a cache holds old data. The same refresh is available with `kubectl`, through the annotation `argocd.argoproj.io/refresh=normal` or `=hard` on the Application.

## Correct the Application and read the operation

The corrected workload `beta` is in `workloads/beta`. Point the Application at it and turn on pruning, so that Argo CD removes the `bad-image` Deployment that is no longer in the source:

```sh
kubectl -n argocd patch application status-demo --type merge -p '{"spec":{"source":{"path":"workloads/beta"},"syncPolicy":{"automated":{"prune":true,"selfHeal":false}}}}'
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/status-demo --timeout=180s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/status-demo --timeout=180s
argocd app get status-demo --show-operation --core
```

The path change makes `beta` a new target and `bad-image` a resource that exists live without a target. Without pruning, Argo CD would create `beta` and still report `OutOfSync`, because it keeps the unknown resource. With pruning, the automated sync deletes `bad-image`. The option `--show-operation` adds the operation state to the output: the phase `Succeeded`, the message, the times and the resources of the last sync.

The workflow is the same for every status problem. Read the sync status and the health status separately. List the resources to find the one that is not `Synced` or not `Healthy`. Use the diff to see what differs, Kubernetes events and logs to see why a workload fails, and the operation state to see how the last sync ended. Then correct the source or the policy, and let Argo CD do the work.

## Common pitfalls

> [!WARNING]
> Do not forget `--core` or the namespace of the context: without the flag the client looks for an API server login, and with the wrong namespace it finds no Applications. Do not expect a refresh to repair anything, it only recomputes the status. Do not change the live Deployment to fix a bad image: with self-healing on, Argo CD reverts it, and with self-healing off it leaves the Application `OutOfSync`. Fix the source instead.

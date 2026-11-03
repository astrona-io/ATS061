---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Sync Options

Argo CD applies each object with `kubectl apply` semantics by default. That default fails for some real cases: a destination namespace that does not exist, an object that is too large for client-side apply, or an object that must be replaced instead of patched. Sync options let you change how a sync treats the whole Application or one object. This part lists the options that the exam expects you to know, shows the two places where you set them, and explains the risks of the destructive ones.

## Two places to set options

Application-level options go in `spec.syncPolicy.syncOptions`, a list of strings:

```yaml
spec:
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    - PruneLast=true
```

An option can also apply to one object. Add the annotation `argocd.argoproj.io/sync-options` to the manifest in Git. Several options go in one value, separated by commas. An annotation on an object wins over the Application setting for that object.

Not every option has both forms. `CreateNamespace` and `ApplyOutOfSyncOnly` exist only at the Application level, while `Prune=false`, `Delete=false`, `Replace=true` and `ServerSideApply` also work as object annotations.

## Options for the namespace and for what is applied

`CreateNamespace=true` makes the sync create the destination namespace when it is missing. Without it, a sync into a missing namespace fails. The option creates a plain namespace. A namespace that needs labels or quotas should be declared as a manifest in Git instead.

`ApplyOutOfSyncOnly=true` makes the sync apply only the objects that are out of sync, and skip the objects that already match. For an Application with thousands of objects this reduces the load on the API server. Hooks still run and the sync is still recorded in history.

`Validate=false` applies the object without client-side schema validation. Use it only for an object that the validation step rejects wrongly.

## Options for deletion

`Prune=false` on an object keeps it from being pruned. `Prune=confirm` holds the sync until a person confirms the delete. `Delete=false` keeps the object when the whole Application is deleted, and `Delete=confirm` asks for confirmation first.

`PruneLast=true` changes the order of pruning: the sync prunes as a last implicit wave, after the other objects are applied and healthy. This is useful when the new objects must run before the old ones disappear, for example during a rename.

`PrunePropagationPolicy=foreground` sets how Kubernetes deletes the children of a pruned object. The values are `foreground`, which is the default, `background` and `orphan`.

## Options for how an object is applied

`ServerSideApply=true` makes Argo CD use server-side apply. The API server then tracks which field belongs to which manager, which avoids conflicts and removes the size limit of the `last-applied-configuration` annotation. It is the usual answer when a large CustomResourceDefinition fails to apply with an annotation-size error.

`Replace=true` makes Argo CD run `kubectl replace` or `kubectl create` instead of `kubectl apply`. This can delete and recreate fields and is destructive. `Force=true` deletes and recreates the object. Both change running workloads, so use them only for objects that have no data to lose. If `Replace=true` and `ServerSideApply=true` are both set, `Replace=true` wins.

`FailOnSharedResource=true` fails the sync when another Application already applied the same object. `RespectIgnoreDifferences=true` makes the sync honor `ignoreDifferences` when it applies, not only when it compares; it affects only objects that already exist.

## Example Application

This Application syncs the `waves` path with a created namespace, a late prune and a reduced apply set. Save it as `application-ordered.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ordered
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: waves
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
    syncOptions:
    - CreateNamespace=true
    - PruneLast=true
    - ApplyOutOfSyncOnly=true
```

Apply it and wait for the Application to become healthy:

<!-- astrona:playground:renew -->

```sh
kubectl apply -f application-ordered.yaml
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/ordered --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/ordered --timeout=240s
```

Then check that the ConfigMap and the Service exist and that the hook Jobs are gone:

```sh
kubectl -n starfleet get configmap wave-config
kubectl -n starfleet get service wave-app
kubectl -n starfleet get jobs
```

The first two commands should print the objects. The Job list should not contain `wave-presync` or `wave-postsync`, because the delete policy `HookSucceeded` removed them. Read the syncOptions that the controller stored:

```sh
kubectl -n argocd get application ordered -o jsonpath='{.spec.syncPolicy.syncOptions}'
```

The list should contain the three options. Then read the result of every resource and hook of the last sync:

```sh
kubectl -n argocd get application ordered -o jsonpath='{range .status.operationState.syncResult.resources[*]}{.kind}{" "}{.name}{" "}{.syncPhase}{" "}{.status}{"\n"}{end}'
```

The command prints one line per resource with its kind, name, sync phase and status. Hook entries show `PreSync` or `PostSync`.

## Choosing options

Start with no options and add one only when a sync fails for a known reason. A missing namespace points to `CreateNamespace=true`. An annotation-size error points to `ServerSideApply=true`. A slow sync of a huge Application points to `ApplyOutOfSyncOnly=true`. Reaching first for `Replace=true` or `Force=true` hides the real cause and risks data loss.

## What the part showed

Sync options adjust how Argo CD applies and deletes, at the Application level or per object. Each option answers a specific failure or cost, and the destructive ones need a reason. Together with phases, waves and hooks they describe how a single sync operation behaves. What remains is what happens after it, how to read its result, retry it and roll back to an earlier revision.

## Common pitfalls

> [!WARNING]
> `CreateNamespace=true` creates a namespace with no labels. A namespace that must carry labels, for example for a security policy, has to come from a manifest in Git. Also, `Replace=true` and `Force=true` can restart or delete running workloads, so never set them on the whole Application of a production service.

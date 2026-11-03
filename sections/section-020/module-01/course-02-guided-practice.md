---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Repair Live Drift With Self Healing In The Playground

This walk-through uses the module playground to see each behavior described so far happen on a real cluster. You create one Application, sync it by hand, turn on automation, and then watch Argo CD undo a change that you make directly in the cluster. Run the commands in order. Each step says what it should show, and the final step explains how to tell a correct result from a wrong one.

Connect to the playground cluster. A kubeconfig is the file that tells `kubectl` which cluster to use:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-020-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-020-01`. Then check that Argo CD runs and that no Application exists:

```sh
kubectl -n argocd get pods
kubectl -n argocd get applications
```

The pods of the Argo CD components should reach `Running`. The Application list should be empty.

## Create an Application without a sync policy

Save this as `application-mission.yaml`. It reads the `plain` path of the in-cluster Git server and has no `syncPolicy`:

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
```

Apply it:

```sh
kubectl apply -f application-mission.yaml
```

Then check the result. After a few seconds the controller finishes its first comparison:

```sh
kubectl -n argocd get application mission
kubectl -n starfleet get deployments
```

The Application should report `OutOfSync` and its health should be `Missing`, because nothing is applied. The `starfleet` namespace should hold no `git-probe` Deployment. This confirms that an Application without a policy only compares.

## Sync by hand

Select the `argocd` namespace for the CLI and log in to core mode, then request the sync:

```sh
kubectl config set-context --current --namespace=argocd
argocd login --core
argocd app sync mission --core
```

The command waits until the operation ends. Afterwards the Application should be `Synced`, and the Deployment `git-probe` should exist with two replicas. Read the operation phase:

```sh
kubectl -n argocd get application mission -o jsonpath='{.status.operationState.phase}'
```

The value should be `Succeeded`.

## Watch drift without self-heal

Scale the Deployment by hand, which changes the live state and not Git:

```sh
kubectl -n starfleet scale deployment/git-probe --replicas=1
kubectl -n argocd get application mission
```

The Application should return to `OutOfSync` after the next comparison, which can take a short time. The replica count stays at one. Argo CD reports the drift and does nothing, because no automated policy exists.

## Turn on automation with self-heal

Save this as `application-mission.yaml` again, now with a sync policy. The file replaces the earlier version of the same name:

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

Apply it, then wait for the controller to restore the declared replica count:

```sh
kubectl apply -f application-mission.yaml
kubectl -n starfleet wait --for=jsonpath='{.spec.replicas}'=2 deployment/git-probe --timeout=180s
```

The wait should end successfully: the policy change made the Application `OutOfSync` with drift, and the self-heal sync wrote `replicas: 2` again.

## Repeat the drift

Scale down once more and watch the controller undo it:

```sh
kubectl -n starfleet scale deployment/git-probe --replicas=1
kubectl -n starfleet wait --for=jsonpath='{.spec.replicas}'=2 deployment/git-probe --timeout=180s
kubectl -n argocd get application mission -o jsonpath='{.status.sync.status}'
```

The replica count should return to two within the self-heal delay plus the sync time, and the status should be `Synced`. If the wait times out, read `kubectl -n argocd get application mission -o yaml` and look at `status.conditions` and `status.operationState.message`.

## What you proved

You proved four things. An Application without policy only reports. A manual sync applies the desired state and records an operation. Drift is only reported while `selfHeal` is off. With `selfHeal: true` the controller restores the declared value on its own. The graded lab that follows asks you to reach the same end state in a fresh environment.

## Common pitfalls

> [!WARNING]
> Change the replica count of the Deployment only after the first sync has finished, or you test a half-applied Application. If you scale the Deployment while the Application is still `Missing`, the sync creates the Deployment from Git and your change is lost without proving anything about self-heal.

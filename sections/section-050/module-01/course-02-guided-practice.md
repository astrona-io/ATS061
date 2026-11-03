---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Ignore Replica Drift In The Playground

The earlier parts described refresh, drift and ignore rules. In this part you build one Application three times and change one setting each time. After each change you scale and edit the Deployment by hand and read what Argo CD does. The goal is to see with your own eyes which setting keeps a hand edit, which setting reverts it and which setting only changes the status. All commands run against the playground cluster, which has Argo CD and the Git server in the namespace `argocd`.

## Connect and look at the starting state

Connect to the playground cluster and select the namespace `argocd`, so the `argocd` client in core mode finds the Application objects:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-050-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-050-01`. Check that no Application exists and that the target namespace has no Deployment named `git-probe`:

```sh
kubectl -n argocd get applications
kubectl -n starfleet get deployment git-probe
```

The first command lists nothing and the second one reports that the Deployment was not found. The Git server holds the path `plain` with a Deployment that has two replicas. That value is the target state.

## Round one: no ignore rule

Save this Application as `application-mission.yaml`. It has automated sync with prune and self-heal, and no ignore rule:

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
    syncOptions:
    - CreateNamespace=true
```

Apply it and wait until the Application is healthy:

```sh
kubectl apply -f application-mission.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s
```

Scale the Deployment by hand and read the count a few seconds later, then again after about 15 seconds:

```sh
kubectl -n starfleet scale deployment git-probe --replicas=4
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

The count returns to 2. The application controller saw the change event, compared the live state with the target state, found a difference in `spec.replicas` and started a sync because self-heal is on. This is the behaviour you want for an object that only Git owns.

## Round two: ignore the field, without the sync option

Save the same Application again with an ignore rule for the replica count, as `application-mission.yaml`. Add this block at the end of `spec` and keep everything else:

```yaml
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

Apply it, scale the Deployment and wait about 30 seconds. Then read the sync status and the count:

```sh
kubectl apply -f application-mission.yaml
kubectl -n starfleet scale deployment git-probe --replicas=4
kubectl -n argocd get application mission -o jsonpath='{.status.sync.status}{"\n"}'
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

The status is `Synced` and the count is 4. The comparison leaves the field out, so no difference exists and self-heal has nothing to repair. Now change something that the rule does not cover. Set the image to another tag and watch the sync:

```sh
kubectl -n starfleet set image deployment/git-probe git-probe=docker.io/library/python:3.12-alpine
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

Run the second command after about 20 seconds. The image is back to `python:3.13-alpine`, so self-heal ran. The count is 2 again. The sync applied the whole target state, including `replicas: 2`, because the ignore rule affected only the comparison. This is the trap of a rule without the sync option: the hand edit survives only until the next sync for any other reason.

## Round three: respect the rule during the sync

Add the sync option. Change the `syncOptions` list in `application-mission.yaml` so it reads:

```yaml
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
```

Apply the file, then repeat the scale and the image change in one go, and read both values after about 20 seconds:

```sh
kubectl apply -f application-mission.yaml
kubectl -n starfleet scale deployment git-probe --replicas=4
kubectl -n starfleet set image deployment/git-probe git-probe=docker.io/library/python:3.12-alpine
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The image is back to `python:3.13-alpine` and the count is still 4. Self-heal repaired the image, and the sync took the live replica count into the desired state before it applied it. Replica drift stays invisible, and image drift stays repaired. This is the result a narrow ignore rule with the sync option gives.

## What to look for when it does not work

If the count in round three returns to 2, check that the sync option is in the live Application. Read it with `kubectl -n argocd get application mission -o jsonpath='{.spec.syncPolicy.syncOptions}{"\n"}'`. A missing `RespectIgnoreDifferences=true` is the usual cause. If the status stays `OutOfSync` in round two, check that the `group` is `apps` and the `kind` is `Deployment`, because a wrong group makes the rule match nothing.

## What the part showed

You saw self-heal revert a hand edit, saw an ignore rule make the comparison blind to one field and saw that the same rule does not protect the field during a sync unless the sync option is on. You also saw that the rule stayed narrow: the image change was still found and repaired.

## Common pitfalls

> [!WARNING]
> Apply a changed Application with `kubectl apply` and wait for a fresh comparison before you test. Reading the replica count only a second after the change can show the old value, because the controller needs a few seconds to react. Also, an image change that Argo CD repairs also resets the replica count when `RespectIgnoreDifferences=true` is missing, so test both fields together.

---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Bring The Bridge Systems Under Argo CD Control Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-030)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-030`.

## Create the restricted project

The project limits where and what the bridge Application may deploy. Save this as `project-bridge.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: bridge
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
  - group: ""
    kind: Service
```

Apply it:

```sh
kubectl apply -f project-bridge.yaml
```

Then check the result:

```sh
kubectl -n argocd get appproject bridge -o jsonpath='{.spec.destinations}{"\n"}{.spec.namespaceResourceWhitelist}{"\n"}'
```

The output should show one destination and the two allowed kinds. Run `astrona submit` to check this step. It reports the other requirements as missing, which is expected.

## Create the bridge Application

The Application uses the production values file, overrides the image tag with a parameter and ignores the replica count. Save this as `application-probe-chart.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: probe-chart
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: bridge
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: chart
    helm:
      valueFiles:
      - values-prod.yaml
      parameters:
      - name: image.tag
        value: 3.12-alpine
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
  syncPolicy:
    automated:
      selfHeal: true
```

Apply it:

```sh
kubectl apply -f application-probe-chart.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-chart --timeout=240s
kubectl -n argocd get application probe-chart -o jsonpath='{.status.sync.status}{"\n"}{.status.conditions}{"\n"}'
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The Application should be `Synced` with no conditions. The Deployment should show `3` replicas and the image `docker.io/library/python:3.12-alpine`. If the Application shows a condition that mentions the project, compare the project with the Application. Run `astrona submit` to check this step.

## Create the parent Application

The parent syncs the path `apps` into the namespace `argocd`. Save this as `application-fleet.yaml`:

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

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/alpha --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/beta --timeout=240s
kubectl -n argocd get applications -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
```

The list should show `probe-chart`, `fleet`, `alpha` and `beta`, all `Synced` and `Healthy`. Run `astrona submit` to check this step.

## Read the tracking annotations

Argo CD writes the annotations on its own. Read them to confirm who owns what:

```sh
kubectl -n starfleet get deployment git-probe -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
kubectl -n argocd get application alpha -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
```

The first value should start with `probe-chart:` and the second with `fleet:`. Run `astrona submit` for the last time. The submit scales the Deployment to five replicas for a short time to test the ignored difference and sets it back to three.

After recording your result, remove the lab with `astrona destroy ats-061-capstone-030`.

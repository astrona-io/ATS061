---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Repair And Extend The Fleet Rendering Setup Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-capstone-040)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-capstone-040`.

## Find the render error

Read the condition of the broken Application:

```sh
kubectl -n argocd get application fleet-chart -o jsonpath='{.status.sync.status}{" "}{.status.conditions[0].type}{"\n"}'
kubectl -n argocd get application fleet-chart -o jsonpath='{.status.conditions[0].message}{"\n"}'
```

The sync status is `Unknown` and the condition type is `ComparisonError`. The message names the values file `values-production.yaml`, which does not exist in the chart. A render error leaves the cluster unchanged, so nothing is deployed.

## Repair fleet-chart

Replace the file name and add the other two layers. A parameter is the strongest source, so it sets 4 replicas even though the file sets 3. Save this as `application-fleet-chart.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fleet-chart
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: chart
    helm:
      valueFiles:
      - values-prod.yaml
      valuesObject:
        image:
          tag: 3.12-alpine
      parameters:
      - name: replicas
        value: "4"
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
kubectl apply -f application-fleet-chart.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/fleet-chart --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/fleet-chart --timeout=240s
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The output is `4 docker.io/library/python:3.12-alpine`. Run `astrona submit` to record the first checks.

## Create the development Application

The image override keeps the image name and replaces the tag. Save this as `application-bridge-dev.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bridge-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: kustomize/overlays/dev
    kustomize:
      images:
      - docker.io/library/python:3.12-alpine
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply it and check the result:

```sh
kubectl apply -f application-bridge-dev.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/bridge-dev --timeout=240s
kubectl -n starfleet get deployment dev-git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

## Create the production Application

The replica override names the base Deployment `git-probe`, not the prefixed name. Save this as `application-bridge-prod.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bridge-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: kustomize/overlays/prod
    kustomize:
      replicas:
      - name: git-probe
        count: 2
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply it and check the result:

```sh
kubectl apply -f application-bridge-prod.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/bridge-prod --timeout=240s
kubectl -n starfleet get deployment prod-git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

The overlay sets 3 replicas, and the Application override replaces it, so the output is `2`. Run `astrona submit` again.

## Check that no render error remains

```sh
kubectl -n argocd get applications -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
kubectl -n argocd get applications -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.conditions}{"\n"}{end}'
```

All three Applications are `Synced` and `Healthy`, and the conditions are empty. Run `astrona submit` a last time.

After recording your result, remove the lab with `astrona destroy ats-061-capstone-040`.

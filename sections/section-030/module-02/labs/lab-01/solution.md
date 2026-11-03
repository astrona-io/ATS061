---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Override A Helm Chart And A Kustomize Overlay And Ignore Replicas Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-030-02-01`.

## Create the production Application from the chart

The values file gives three replicas. The parameter sets the image tag, and the `ignoreDifferences` entry removes the replica count from the comparison. Save this as `application-probe-prod.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: probe-prod
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
kubectl apply -f application-probe-prod.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/probe-prod --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-prod --timeout=240s
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The Deployment should show `3` replicas and the image `docker.io/library/python:3.12-alpine`. Run `astrona submit` to check this step. It reports the development Application as missing, which is expected.

## Create the development Application from the overlay

The Kustomize image override replaces the tag of the image that the base uses. Save this as `application-probe-dev.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: probe-dev
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
    automated: {}
```

Apply it:

```sh
kubectl apply -f application-probe-dev.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/probe-dev --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-dev --timeout=240s
kubectl -n starfleet get deployment dev-git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The Deployment should show `1` replica and the image `docker.io/library/python:3.12-alpine`. Run `astrona submit` to check this step.

## Prove that the replica count is ignored

Scale the production Deployment by hand and check that the Application does not call it drift:

```sh
kubectl -n starfleet scale deployment git-probe --replicas=5
kubectl -n argocd get application probe-prod -o jsonpath='{.status.sync.status}{"\n"}'
```

The Application should stay `Synced` and the Deployment should keep `5` replicas. Set the replicas back to the value of the values file and run `astrona submit` for the last time:

```sh
kubectl -n starfleet scale deployment git-probe --replicas=3
```

The last check scales the Deployment itself and sets it back to `3` when it finishes.

After recording your result, remove the lab with `astrona destroy ats-061-lab-030-02-01`.

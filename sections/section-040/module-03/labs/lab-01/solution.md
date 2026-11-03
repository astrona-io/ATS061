---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Override Kustomize Overlays From Two Applications Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-03-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-03-01`.

## Create the development Application

The image override uses the format `name:tag`, which keeps the image name and replaces the tag. The common annotation goes under `commonAnnotations`. Save this as `application-dev-fleet.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-fleet
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
      commonAnnotations:
        fleet.starfleet/owner: operations
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
kubectl apply -f application-dev-fleet.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/dev-fleet --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/dev-fleet --timeout=240s
kubectl -n starfleet get deployment dev-git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The output is `1 docker.io/library/python:3.12-alpine`. Run `astrona submit` to record the first checks.

## Create the production Application

An inline patch is a strategic merge patch. It names the base Deployment `git-probe` and the namespace `starfleet`, because the base sets that namespace and the patch must match the target. The patch does not use the prefixed name. Save this as `application-prod-fleet.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prod-fleet
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: kustomize/overlays/prod
    kustomize:
      patches:
      - patch: |-
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: git-probe
            namespace: starfleet
          spec:
            template:
              spec:
                containers:
                - name: git-probe
                  resources:
                    requests:
                      cpu: 25m
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
kubectl apply -f application-prod-fleet.yaml
```

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/prod-fleet --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/prod-fleet --timeout=240s
kubectl -n starfleet get deployment prod-git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].resources.requests.cpu}{"\n"}'
```

The output is `3 25m`. If the Application shows a `ComparisonError`, read `kubectl -n argocd get application prod-fleet -o jsonpath='{.status.conditions[0].message}'` and check that the patch names `git-probe` and `starfleet`. Run `astrona submit` again.

After recording your result, remove the lab with `astrona destroy ats-061-lab-040-03-01`.

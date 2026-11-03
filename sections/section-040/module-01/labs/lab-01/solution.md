---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Render A Helm Chart With A Production Values File Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-01-01`.

## Create the Application

Argo CD selects Helm because the path `chart` holds a `Chart.yaml` file. The field `spec.source.helm.valueFiles` lists extra values files, relative to the chart directory. Save this as `application-mission.yaml`:

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
    path: chart
    helm:
      valueFiles:
      - values-prod.yaml
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
kubectl apply -f application-mission.yaml
```

Then check the result. The first command waits for the sync, the second waits for health, and the third prints the source type:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s
kubectl -n argocd get application mission -o jsonpath='{.status.sourceType}{"\n"}'
```

The source type is `Helm`. Run `astrona submit` to check the Application and its sync state.

## Check the rendered Deployment

Read the replica count and the image that Helm rendered:

```sh
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The replica count is `3` from `values-prod.yaml`, and the image is `docker.io/library/python:3.13-alpine` from the chart default, because the production file sets only the replicas. Run `astrona submit` again.

After recording your result, remove the lab with `astrona destroy ats-061-lab-040-01-01`.

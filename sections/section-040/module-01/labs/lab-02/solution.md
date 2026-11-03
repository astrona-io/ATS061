---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Deploy A Kustomize Overlay With Argo CD Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-01-02)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-01-02`.

## Create the Application

Argo CD builds the directory named by `spec.source.path`. The directory `kustomize/overlays/prod` has a `kustomization.yaml` file, so Argo CD selects Kustomize and the overlay adds its prefix, label, replica count and image tag to the base. Save this as `application-mission.yaml`:

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
    path: kustomize/overlays/prod
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

Then check the result:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s
kubectl -n argocd get application mission -o jsonpath='{.status.sourceType}{"\n"}'
```

The source type is `Kustomize`. Run `astrona submit` to check the Application and its sync state.

## Check the built objects

List the Deployments with the label column and read the image:

```sh
kubectl -n starfleet get deployments -L environment
kubectl -n starfleet get deployment prod-git-probe -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

Only `prod-git-probe` is listed, with 3 replicas and the value `prod` in the label column. The image tag is `3.12-alpine` from the overlay. Run `astrona submit` again.

After recording your result, remove the lab with `astrona destroy ats-061-lab-040-01-02`.

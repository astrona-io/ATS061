---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Render Helm And Kustomize Sources In The Playground

Argo CD renders a Helm chart with `helm template` and a Kustomize directory with `kustomize build`. In this chapter you create one Application for each tool in the playground and read the fields that prove which tool ran and what it produced. The playground has Argo CD and a Git server in the `argocd` namespace, and the Git server holds the seed repository.

## Connect to the playground

A kubeconfig is the file that tells `kubectl`, the Kubernetes command line tool, which cluster and credentials to use. Set it for the playground and check the context. The second command makes `argocd` core mode, which talks to the Kubernetes API directly, read the Applications from the `argocd` namespace.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-040-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-040-01`. No Application exists yet, and `kubectl get applications` returns no resources.

## Render the Helm chart

Save this Application as `application-probe-helm.yaml`. It points at the directory `chart`, which holds a `Chart.yaml`, so Argo CD selects Helm without a tool block.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: probe-helm
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: chart
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
```

Apply it, wait for the controller, and then read the three status fields that describe the render:

```sh
kubectl apply -f application-probe-helm.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-helm --timeout=240s
kubectl -n argocd get application probe-helm -o jsonpath='{.status.sourceType}{"\n"}{.status.sync.revision}{"\n"}{.status.summary.images}{"\n"}'
```

The first line is `Helm`. The second line is the commit that Argo CD resolved from `main`. The third line lists the image of the Deployment, `docker.io/library/python:3.13-alpine`, because the chart default sets that tag. The Deployment `git-probe` in `starfleet` has two replicas.

## Check that Helm installed nothing

Helm stores an installed release as a Secret of the type `helm.sh/release.v1`. Ask the cluster for Secrets of that type in every namespace:

```sh
kubectl get secrets --all-namespaces --field-selector type=helm.sh/release.v1
```

The command finds no resources. Argo CD rendered the chart and applied the objects itself, so no release record exists and `helm list` would show nothing for this Application.

## Render a Kustomize overlay

Save a second Application as `application-probe-dev.yaml`. Its path is the `dev` overlay, and the directory has a `kustomization.yaml`, so Argo CD selects Kustomize.

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
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
```

Apply it and list the Deployments with the `environment` label as an extra column:

```sh
kubectl apply -f application-probe-dev.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-dev --timeout=240s
kubectl -n starfleet get deployments -L environment
```

The list now shows `git-probe` from the chart, with two replicas and no value in the label column, and `dev-git-probe` from the overlay, with one replica and the value `dev`. The prefix, the label and the replica count all came from the overlay, and the base file was not changed. The field `status.sourceType` of `probe-dev` is `Kustomize`.

## Read the rendered manifests

The command `argocd app manifests` prints the manifests that the repository server rendered for an Application. Core mode needs the flag `--core` on every command:

```sh
argocd app manifests probe-dev --core
```

The output is the Deployment and the Service of the overlay, with the names `dev-git-probe`, the label `environment: dev` and one replica. This is what the controller compares with the cluster. When a live object differs from this output, the Application is `OutOfSync`.

## Change the path

Edit `application-probe-dev.yaml` so that `path` is `kustomize/overlays/prod`, apply it again and wait for the Application to become healthy. Then list the Deployments once more:

```sh
kubectl apply -f application-probe-dev.yaml
kubectl -n starfleet get deployments -L environment
```

Because automated sync has `prune: true`, Argo CD deletes `dev-git-probe`, which the new path no longer renders, and creates `prod-git-probe` with three replicas and the label value `prod`. Reading the image with `kubectl -n argocd get application probe-dev -o jsonpath='{.status.summary.images}'` shows the tag `3.12-alpine` from the production overlay.

## What the chapter showed

You created an Application for a Helm chart and one for a Kustomize overlay, and you read the tool, the revision and the image from the Application status. You also saw that Helm leaves no release behind, that an overlay changes names, labels and replicas, and that changing only the path replaces the whole result. The remaining question is how to change the rendered result from the Application itself, without a new commit.

## Common pitfalls

> [!WARNING]
> Run `argocd` in core mode with the flag `--core` and the namespace `argocd` in the `kubectl` context, or it tries to reach a server that the cluster does not expose. Look for `dev-git-probe`, not `git-probe`, when an overlay adds a prefix. Do not delete the Git server: it holds every source that these Applications read.

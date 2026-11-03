---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Layer Helm Values And Break A Values File In The Playground

You now know the order of the Helm value sources and the settings around them. In this chapter you build one Application with three layers of values, remove the layers one at a time and watch the Deployment change. You then point the Application at a missing values file and read the comparison error that Argo CD reports. The playground has Argo CD and the Git server in the `argocd` namespace.

## Connect to the playground

A kubeconfig is the file that tells `kubectl`, the Kubernetes command line tool, which cluster and credentials to use. Set it for the playground and check the context.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-040-02)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-040-02`. No Application exists yet.

## Create the layered Application

Save this Application as `application-layers.yaml`. It uses all three override sources on the seed chart. Its destination namespace is `outpost`, which the chart does not use, because the chart templates name `starfleet`.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: probe-layers
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
        replicas: 2
        image:
          tag: 3.12-alpine
      parameters:
      - name: replicas
        value: "4"
  destination:
    server: https://kubernetes.default.svc
    namespace: outpost
  syncPolicy:
    automated:
      prune: true
```

Apply it, wait until it is healthy and read the replica count and the image of the Deployment:

```sh
kubectl apply -f application-layers.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-layers --timeout=240s
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The output is `4 docker.io/library/python:3.12-alpine`. The parameter won the replica count, the `valuesObject` set the tag and the file `values-prod.yaml` lost its key to both. The Deployment sits in `starfleet`, so `kubectl -n outpost get deployments` finds nothing, because the manifests name their own namespace.

## Remove the strongest layer

Remove the parameters with a JSON patch and wait for the Deployment to follow. A JSON patch lists operations on exact paths in the object.

```sh
kubectl -n argocd patch application probe-layers --type json -p '[{"op":"remove","path":"/spec/source/helm/parameters"}]'
kubectl -n starfleet wait --for=jsonpath='{.spec.replicas}'=2 deployment/git-probe --timeout=120s
```

The wait succeeds. With the parameter gone, the `valuesObject` is the strongest source, and it sets `replicas: 2`. The value `3` in the file never won in this Application, because a stronger layer always set the key. Removing a layer reveals the next one, which is the fastest way to find out which source owns a value.

## Point the Application at a missing file

Replace the values file with a name that does not exist in the chart, and read the condition that Argo CD sets on the Application:

```sh
kubectl -n argocd patch application probe-layers --type json -p '[{"op":"replace","path":"/spec/source/helm/valueFiles/0","value":"values-staging.yaml"}]'
kubectl -n argocd wait --for=jsonpath='{.status.conditions[0].type}'=ComparisonError application/probe-layers --timeout=120s
kubectl -n argocd get application probe-layers -o jsonpath='{.status.conditions[0].message}{"\n"}'
```

The condition type is `ComparisonError`, and the message says that Helm could not open the file `values-staging.yaml`. The repository server cannot render, so the controller has no new desired state. The Deployment in `starfleet` is not touched, and it keeps running with the last values that rendered.

## Ignore the missing file

Set `ignoreMissingValueFiles` so that Argo CD skips the file, and check that the error goes away:

```sh
kubectl -n argocd patch application probe-layers --type merge -p '{"spec":{"source":{"helm":{"ignoreMissingValueFiles":true}}}}'
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/probe-layers --timeout=120s
kubectl -n argocd get application probe-layers -o jsonpath='{.status.conditions}{"\n"}'
```

The Application is `Synced` again and the conditions list is empty. The render used the `valuesObject` and the chart defaults, and it skipped the missing file without any message. That silence is the danger of the setting: a typo in a file name now changes the configuration without an error.

## What the chapter showed

You built an Application where a parameter, an object and a file all set the same key, and you saw that the parameter wins and that removing a layer exposes the next one. You also saw that a missing values file stops the render with a comparison error that leaves the live objects unchanged, and that ignoring missing files trades the error for silence. A chart that fails to render is a chart problem, not a cluster problem.

## Common pitfalls

> [!WARNING]
> A JSON patch with a wrong path fails or removes the wrong field, so read the Application with `kubectl get application probe-layers -o yaml` before you patch it. A `ComparisonError` means the render failed, not that the sync failed, and the cluster keeps its old objects. `ignoreMissingValueFiles` hides typos, so turn it on only for files that are optional by design.

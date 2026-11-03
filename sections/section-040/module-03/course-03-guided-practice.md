---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Override An Overlay, Compare Output And Fix A Broken Path In The Playground

In this chapter you deploy the production overlay with two overrides, print the rendered manifests, create a difference in the cluster and read it, and break the Application with a wrong path. Each step uses a field or a command that proves what Argo CD did. The playground has Argo CD and the Git server in the `argocd` namespace.

## Connect to the playground

A kubeconfig is the file that tells `kubectl`, the Kubernetes command line tool, which cluster and credentials to use. Set it for the playground, make `argocd` the default namespace and check the context. The `argocd` command line client uses core mode, which reads the Applications from that namespace, so every `argocd` command in this chapter carries `--core`.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-040-03)"
kubectl config set-context --current --namespace=argocd
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-040-03`. No Application exists yet.

## Deploy the production overlay with overrides

Save this Application as `application-probe-prod.yaml`. It builds the production overlay, replaces the image tag with `3.13-alpine`, sets two replicas and adds an owner annotation. Automated sync has no `selfHeal`, so Argo CD applies Git changes but does not undo changes made by hand.

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
    targetRevision: v1.0.0
    path: kustomize/overlays/prod
    kustomize:
      images:
      - docker.io/library/python:3.13-alpine
      replicas:
      - name: git-probe
        count: 2
      commonAnnotations:
        fleet.starfleet/owner: operations
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
```

The revision is the tag `v1.0.0`, so the Application renders the same commit even if `main` changes. Apply it, wait for health and read the image list:

```sh
kubectl apply -f application-probe-prod.yaml
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-prod --timeout=240s
kubectl -n argocd get application probe-prod -o jsonpath='{.status.sourceType}{" "}{.status.sync.revision}{" "}{.status.summary.images}{"\n"}'
```

The source type is `Kustomize`, and the image list holds `docker.io/library/python:3.13-alpine`. The overlay alone would give `3.12-alpine`, so the override won. The revision is the commit that the tag `v1.0.0` points at.

## Print the rendered manifests

Print the manifests that the repository server rendered and filter the lines that the overrides changed:

```sh
argocd app manifests probe-prod --core | grep -E 'name: prod-|replicas:|image:|fleet.starfleet/owner'
```

The output shows the prefixed names `prod-git-probe`, two replicas, the image with the tag `3.13-alpine` and the annotation on the Deployment, the Service and the pod template. Compare this with the cluster: `kubectl -n starfleet get deployment prod-git-probe` reports two ready replicas.

## Create a difference in the cluster

Scale the Deployment by hand and read the sync status. Because `selfHeal` is off, Argo CD does not undo the change:

```sh
kubectl -n starfleet scale deployment/prod-git-probe --replicas=5
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=OutOfSync application/probe-prod --timeout=120s
argocd app diff probe-prod --core
```

The status becomes `OutOfSync`, because the live replica count of 5 differs from the rendered 2. The diff command prints the difference between the live and the desired Deployment, and the changed field is `spec.replicas`. A sync would set it back to 2.

## Break the path and read the error

Change the path to a directory that does not exist, wait for the error condition and read its message:

```sh
kubectl -n argocd patch application probe-prod --type merge -p '{"spec":{"source":{"path":"kustomize/overlays/staging"}}}'
kubectl -n argocd wait --for=jsonpath='{.status.conditions[0].type}'=ComparisonError application/probe-prod --timeout=120s
kubectl -n argocd get application probe-prod -o jsonpath='{.status.sync.status}{" "}{.status.conditions[0].message}{"\n"}'
```

The sync status is `Unknown` and the message says that the path does not exist in the repository. The Deployment in `starfleet` still runs with five replicas, because a render error changes nothing in the cluster.

## Fix the path and force a fresh render

Restore the path, ask for a hard refresh and check that the error is gone:

```sh
kubectl -n argocd patch application probe-prod --type merge -p '{"spec":{"source":{"path":"kustomize/overlays/prod"}}}'
kubectl -n argocd annotate application probe-prod argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=OutOfSync application/probe-prod --timeout=120s
```

The condition disappears, and the Application is `OutOfSync` again because of the five replicas that you set by hand. The hard refresh made Argo CD render again without its cache.

## What the chapter showed

You overrode an overlay from the Application, read the tool, the revision and the image from its status, and printed the rendered manifests. You created a live difference and saw it as `OutOfSync`, and you saw that a wrong path gives a `ComparisonError` and the sync status `Unknown` while the cluster keeps its objects. Each of these facts is a step in a normal diagnosis of a rendering problem.

## Common pitfalls

> [!WARNING]
> Name the base resource in `replicas`, which is `git-probe`, and look for `prod-git-probe` in the cluster. Run `argocd` with `--core` and with the namespace `argocd` in the `kubectl` context. A render error leaves the live objects unchanged, so a working workload does not prove that the new configuration renders.

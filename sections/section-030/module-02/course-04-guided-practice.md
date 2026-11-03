---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Override Helm Values And Ignore A Field In The Playground

A Helm override is easy to write and easy to misjudge, because several value sources compete. This practice renders the seed chart with a values file, adds a parameter that beats it, deploys the result and then tells Argo CD to ignore the replica count. At each step you read a live field to see which source won. The playground has Argo CD, the Git server at `http://git-source.argocd.svc:8080/repo.git` and no Application.

## Connect to the playground

Point `kubectl` at the playground cluster, set the `argocd` namespace in the context for the `argocd` command line client, and check the context:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-030-02)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

The context must be `kind-astro-ats-061-playground-030-02`.

## Render the chart with a values file

The chart in the path `chart` has two replicas by default and the file `values-prod.yaml` sets three. Save this as `application-drill-chart.yaml`. It uses the values file and no sync policy yet:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: drill-chart
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
```

Apply it:

```sh
kubectl apply -f application-drill-chart.yaml
```

Then check the rendered replica count without deploying anything. The `argocd` client prints the rendered manifests of the Application:

```sh
argocd app manifests drill-chart --core | grep -E 'replicas|image:'
```

You should see `replicas: 3` and the image with the tag `3.13-alpine`.

## Add a parameter that beats the values file

Set a parameter for the image tag and a `valuesObject` for the replicas, then render again. The command patches the Application:

```sh
kubectl -n argocd patch application drill-chart --type merge -p '{"spec":{"source":{"helm":{"valuesObject":{"replicas":4},"parameters":[{"name":"image.tag","value":"3.12-alpine"}]}}}}'
argocd app manifests drill-chart --core | grep -E 'replicas|image:'
```

The replicas should now be `4`, because `valuesObject` beats `valueFiles`, and the tag should be `3.12-alpine` from the parameter. Add a parameter `replicas` with the value `5` to the list and render once more to see that a parameter beats `valuesObject`. Remove the `replicas` value from `valuesObject` afterwards if you want to return to the values file.

## Deploy and prove the result in the cluster

Sync the Application and read the live Deployment:

```sh
argocd app sync drill-chart --core
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
```

The live Deployment should have the replica count and the image tag that the last render showed. The values came from the Application and the values file, and the Deployment holds the merged result.

## Ignore the replica count

Another controller could own the replicas, so tell Argo CD to ignore the field and turn on automated sync with `selfHeal`:

```sh
kubectl -n argocd patch application drill-chart --type merge -p '{"spec":{"ignoreDifferences":[{"group":"apps","kind":"Deployment","jsonPointers":["/spec/replicas"]}],"syncPolicy":{"automated":{"selfHeal":true}}}}'
kubectl -n starfleet scale deployment git-probe --replicas=7
kubectl -n argocd get application drill-chart -o jsonpath='{.status.sync.status}{"\n"}'
```

After a few seconds the Application should be `Synced` and the Deployment should keep `7` replicas. Remove the `ignoreDifferences` entry with a patch that sets it to an empty list and watch the Application become `OutOfSync` and then return the Deployment to its rendered replica count.

## Ideas to try on your own

Render the Kustomize overlay `kustomize/overlays/prod` with a `kustomize.images` override and read the manifests. Add `RespectIgnoreDifferences=true` to the sync options, scale the Deployment to `7` and run a sync by hand to see that the ignored field stays. Remove the option and repeat.

## What you saw

You saw that Helm sources combine in the documented order, that the Application renders and deploys the merged result, and that `ignoreDifferences` keeps a live change from making the Application `OutOfSync` and from triggering `selfHeal`.

## Common pitfalls

> [!WARNING]
> `argocd app manifests` needs `--core` and the `argocd` namespace in the `kubectl` context. A merge patch replaces `parameters` as a whole list, so include every parameter you need. After you remove `ignoreDifferences`, automated `selfHeal` changes the replica count back without asking.

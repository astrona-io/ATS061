---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Layer Helm Values For The Fleet Chart Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-040-02-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-040-02-01`.

## Create the Application

The three sources go under `spec.source.helm`. A parameter is the strongest source, so it sets the replica count even though the file sets 3. The `valuesObject` sets only the image tag. Save this as `application-fleet-chart.yaml`:

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
    namespace: outpost
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
kubectl -n argocd get application fleet-chart -o jsonpath='{.status.sourceType}{"\n"}'
```

The source type is `Helm`. Run `astrona submit` to check the Application and its sync state.

## Check the effective values and the namespace

Read the Deployment that Helm rendered and look for objects in the destination namespace:

```sh
kubectl -n starfleet get deployment git-probe -o jsonpath='{.spec.replicas}{" "}{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n outpost get deployments
```

The first command prints `4 docker.io/library/python:3.12-alpine`. The second finds no Deployment: the chart templates name the namespace `starfleet`, so the destination namespace `outpost` does not move the objects. Run `astrona submit` again.

After recording your result, remove the lab with `astrona destroy ats-061-lab-040-02-01`.

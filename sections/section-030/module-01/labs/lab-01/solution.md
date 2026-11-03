---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Restrict An Application To One Repository, Namespace And Kinds Solution

Connect to the lab cluster and check the context:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-01-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-lab-030-01-01`.

## Create the project

The project comes first so that the Application is checked against it from its first reconciliation. The lists name exactly what the task allows. Save this as `appproject-mission.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: mission
  namespace: argocd
spec:
  sourceRepos:
  - http://git-source.argocd.svc:8080/repo.git
  destinations:
  - server: https://kubernetes.default.svc
    namespace: starfleet
  namespaceResourceWhitelist:
  - group: apps
    kind: Deployment
  - group: ''
    kind: Service
```

Apply it:

```sh
kubectl apply -f appproject-mission.yaml
```

Then check the result:

```sh
kubectl -n argocd get appproject mission -o jsonpath='{.spec.destinations[*].namespace}{"\n"}'
```

The output should be `starfleet`. Run `astrona submit` to check this step. It reports the Application as missing, which is expected.

## Create the Application

Save this as `application-mission.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mission
  namespace: argocd
spec:
  project: mission
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: plain
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

Then check the result. Wait for the sync and the health, and print the conditions and the revision:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/mission --timeout=240s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/mission --timeout=240s
kubectl -n argocd get application mission -o jsonpath='{.status.sync.revision}{"\n"}{.status.conditions}{"\n"}'
kubectl -n starfleet get deployment git-probe
```

The revision should be a 40-character SHA and the conditions should be empty. The Deployment should show `2/2` ready. Run `astrona submit` to check the final state.

After recording your result, remove the lab with `astrona destroy ats-061-lab-030-01-01`.

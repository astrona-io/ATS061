---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Generate Environments With An ApplicationSet Solution

Connect to the lab cluster and select the namespace `argocd`:

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-050-03-01)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

## Create the ApplicationSet

The three Applications must not share one namespace, because the base manifests all use the same object names. The template therefore sets the Kustomize namespace from the parameter `environment` and the Kustomize replica override from the parameter `replicas`. Save this as `applicationset-fleet-envs.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: fleet-envs
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - git:
      repoURL: http://git-source.argocd.svc:8080/repo.git
      revision: main
      files:
      - path: 'envs/*/config.json'
  template:
    metadata:
      name: 'probe-{{ .environment }}'
    spec:
      project: default
      source:
        repoURL: http://git-source.argocd.svc:8080/repo.git
        targetRevision: main
        path: kustomize/base
        kustomize:
          namespace: 'probe-{{ .environment }}'
          replicas:
          - name: git-probe
            count: '{{ .replicas }}'
      destination:
        server: https://kubernetes.default.svc
        namespace: 'probe-{{ .environment }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

Apply it:

```sh
kubectl apply -f applicationset-fleet-envs.yaml
```

Then check the result:

```sh
kubectl -n argocd get applications
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-prod --timeout=300s
kubectl -n probe-dev get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n probe-staging get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n probe-prod get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

The list shows three Applications and the counts are 1, 2 and 3. If the list is empty, wait a few seconds and run it again. Run `astrona submit` to check this step.

## Test the repair

The grader edits and deletes generated Applications itself, and you can do the same:

```sh
kubectl -n argocd patch application probe-staging --type merge -p '{"spec":{"source":{"targetRevision":"v1.0.0"}}}'
kubectl -n argocd delete application probe-dev
```

Wait about 30 seconds and read the result:

```sh
kubectl -n argocd get application probe-staging -o jsonpath='{.spec.source.targetRevision}{"\n"}'
kubectl -n argocd get applications
```

The revision of `probe-staging` is `main` and the Application `probe-dev` exists again. Run `astrona submit` once more.

After recording your result, remove the lab with `astrona destroy ats-061-lab-050-03-01`.

---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Generate Applications From Git Files In The Playground

The earlier part used a list that lives inside the ApplicationSet. A list inside the object is simple, but every change to it is a change to the ApplicationSet. In this part the generator reads small data files from Git, so adding an environment means adding one file. You create the ApplicationSet, read what it generated and test what the ApplicationSet controller repairs. All commands run against the playground cluster, which has Argo CD and the Git server in the namespace `argocd`.

## The input files

The Git server holds one file for each environment: `envs/dev/config.json`, `envs/staging/config.json` and `envs/prod/config.json`. Each file has the fields `environment` and `replicas`. The file for `dev` is `{"environment": "dev", "replicas": 1}`, the one for `staging` has the replica count 2 and the one for `prod` has 3. The Git files generator reads every file that matches `envs/*/config.json` and creates one parameter set for each file, with the parameters `environment` and `replicas`.

The workload is the path `kustomize/base`, which holds the Deployment and Service `git-probe` in the namespace `starfleet`. Three Applications cannot share that namespace, because they would own the same objects. The template uses two fields of the Kustomize source of an Application to avoid this. The field `namespace` makes Kustomize place all objects in the given namespace, and the field `replicas` is a list of overrides, each with the name of a Deployment and a count.

## Connect and create the ApplicationSet

Connect to the playground and select the namespace `argocd`:

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-050-03)"
kubectl config current-context
kubectl config set-context --current --namespace=argocd
```

Save this as `applicationset-fleet-envs.yaml`:

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

Apply it and wait for the first Application:

```sh
kubectl apply -f applicationset-fleet-envs.yaml
kubectl -n argocd get applications
```

The list shows `probe-dev`, `probe-staging` and `probe-prod`. If the list is empty, run the command again after a few seconds, because the controller reads Git and creates the Applications in a short delay.

## Read what was generated

Wait until all three are healthy, then read the replica count and the namespace of each environment:

```sh
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/probe-prod --timeout=300s
kubectl -n probe-dev get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n probe-staging get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n probe-prod get deployment git-probe -o jsonpath='{.spec.replicas}{"\n"}'
```

The counts are 1, 2 and 3, the values of the three files. One template and three small files gave three Applications with three separate sets of workloads. Read the owner of one generated Application and the tracking annotation of its Deployment:

```sh
kubectl -n argocd get application probe-staging -o jsonpath='{.metadata.ownerReferences[0].kind}{" "}{.metadata.ownerReferences[0].name}{"\n"}'
kubectl -n probe-staging get deployment git-probe -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}{"\n"}'
```

The first value is `ApplicationSet fleet-envs`, the owner of the Application. The second value starts with `probe-staging:`, the owner of the Deployment. The two owners are different components. The ApplicationSet controller owns the Application and the application controller owns the workload.

## Test what the controller repairs

Edit the generated Application `probe-staging` by hand, with a revision that points to the same commit as `main`:

```sh
kubectl -n argocd patch application probe-staging --type merge -p '{"spec":{"source":{"targetRevision":"v1.0.0"}}}'
kubectl -n argocd get application probe-staging -o jsonpath='{.spec.source.targetRevision}{"\n"}'
```

Run the second command again after about 20 seconds. The value is `main` again, because the ApplicationSet controller saw a generated Application that no longer matches the template and patched it. Self-heal in the template did not do this, because self-heal repairs workloads and not the Application object. Now delete a generated Application and list them:

```sh
kubectl -n argocd delete application probe-dev
kubectl -n argocd get applications
```

The Application `probe-dev` is created again after a short delay, because its parameter set still exists. If you delete the Application and the list shows nothing for a while, wait one minute and list again.

## Find the failing layer

An ApplicationSet adds a layer in front of the Applications, so check the layers in order. If an Application is missing, read the ApplicationSet and its status conditions with `kubectl -n argocd describe applicationset fleet-envs`, because a wrong path pattern, an invalid template or a duplicate name stops the generation. If the Application exists but is `OutOfSync` or shows `ComparisonError`, read the Application, because its source or destination is wrong. If it is `Synced` but `Degraded`, read the workloads. A missing child is almost never a workload problem.

## What the part showed

A Git files generator turned three small JSON files into three Applications with their own namespaces and replica counts. The ApplicationSet controller owns the Applications and patches edits of them back. The application controller owns the workloads. Each layer has its own status, so a fault is found by reading from the ApplicationSet down.

## Common pitfalls

> [!WARNING]
> Do not edit a generated Application to change its settings. The ApplicationSet controller sets it back to the template, so change the template or the input file instead. Also, check that two parameter sets cannot produce the same Application name or the same namespace and object names, or the Applications fight over one object.

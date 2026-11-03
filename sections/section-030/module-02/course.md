---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Directory, Helm And Kustomize Sources, Overrides And ignoreDifferences

Teams keep Kubernetes manifests as plain files, as Helm charts or as Kustomize overlays. An Argo CD Application can read all three, and it can change the rendered result from inside the Application without a new commit. It can also be told to ignore fields that another controller changes on purpose. This module explains how Argo CD detects each source type, how parameter overrides and their precedence work, and how `ignoreDifferences` removes expected differences from the comparison.

## Learning goals

- Say how the repo server decides that a path is a directory, a Helm chart or a Kustomize base.
- Write `spec.source.helm` with `valueFiles`, `valuesObject` and `parameters` and predict which value wins.
- Write `spec.source.kustomize` overrides such as `namePrefix`, `images` and `namespace`.
- Use `spec.ignoreDifferences` with `jsonPointers`, `jqPathExpressions` and `managedFieldsManagers`.
- Explain what `RespectIgnoreDifferences=true` changes during a sync.
- Read the rendered manifests of an Application to check an override.

## What to know first

You need to know what an Application, a sync and a Helm chart are. The playground has Argo CD and a Git server inside the cluster. The seed repository holds a Helm chart in `chart` (values file `values-prod.yaml` with three replicas), a Kustomize base in `kustomize/base` with the overlays `dev` and `prod`, the plain manifests in `workloads/alpha`, `workloads/beta` and `workloads/gamma`, and the path `plain`, which also holds a `kustomization.yaml`.

## Reading order

The first part explains the three source types and how Argo CD detects them. The second part covers Helm and Kustomize overrides. The third part covers `ignoreDifferences`. The fourth part walks through all of them in the playground and ends with a graded lab. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

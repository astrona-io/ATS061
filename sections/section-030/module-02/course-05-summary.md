---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Summary

The repo server turns a Git path into plain manifests and the application controller compares them with the cluster. It treats a path with a `Chart.yaml` as Helm, a path with a `kustomization.yaml` as Kustomize and any other path as a directory of `.yaml`, `.yml` and `.json` files. The Application records the result in `status.sourceType`. Argo CD uses Helm only to inflate a chart with `helm template` and creates no Helm release.

Overrides live in the Application and change only the rendered manifests. Helm values come from `parameters`, `valuesObject`, `values`, `valueFiles` and the `values.yaml` of the chart, and the stronger source replaces the weaker one in that order. Kustomize overrides such as `namePrefix`, `namespace`, `images` and `replicas` replace the fields of the kustomization file. An override is not visible in Git, so it fits values that belong to one Application and does not fit environment differences.

The field `spec.ignoreDifferences` removes fields from the comparison. An entry selects objects with `group`, `kind`, `name` and `namespace` and fields with `jsonPointers`, `jqPathExpressions` or `managedFieldsManagers`. An ignored field does not make the Application `OutOfSync` and does not start `selfHeal`. A sync still writes the desired value of an ignored field unless the sync option `RespectIgnoreDifferences=true` is set, and that option works only for objects that already exist.

- A `kustomization.yaml` makes a path a Kustomize source, even if it looks like plain files.
- Parameters beat `valuesObject`, which beats `values`, which beats `valueFiles`.
- An ignored field stays out of the comparison, not automatically out of a sync.

<!-- astrona:playground:destroy -->

---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Summary

An Application changes the values of a Helm chart in four places under `spec.source.helm`: the list `valueFiles`, the string `values`, the structured `valuesObject` and the list `parameters`. Helm starts from the chart defaults and applies the sources in that order, so a parameter beats a `valuesObject`, which beats `values`, which beats a values file, which beats the chart default. Files apply in list order and the later file wins. The merged result is visible only in the rendered Deployment, so the rendered manifests are the place to check a value.

The release name defaults to the Application name, and the field `releaseName` overrides it. A chart that builds object names or label selectors from the release name changes them when the release name changes, and with pruning on Argo CD deletes the old objects. The destination namespace is the namespace of the release, but a manifest that writes its own namespace keeps it.

Argo CD installs custom resource definitions from a chart unless `skipCrds` is true. It maps Helm hooks to sync hooks: install and upgrade hooks become `PreSync` and `PostSync`, and a hook weight becomes a sync wave. Hooks for both install and upgrade run on every sync, and Argo CD ignores the Helm hooks of a chart that already has Argo CD hook annotations.

A render that fails, for example because a values file is missing, appears as a `ComparisonError` condition and leaves the live objects as they are. A render that differs on every run, because of random functions, keeps the Application `OutOfSync`. Setting a stable parameter fixes it.

- The last source in the order wins for each key.
- A missing values file stops the render unless the Application ignores missing files.
- Random template output makes an Application permanently out of sync.

<!-- astrona:playground:destroy -->

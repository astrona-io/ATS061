---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Helm Values, Parameters And Release Settings

A chart is reusable only because its values can change. In Argo CD the values can come from files in the chart, from structured YAML written into the Application and from single parameters. They can disagree, and Argo CD must pick one answer. This module explains the order, the settings that shape the Helm run besides the values, and the failures that follow when a value file is missing or a chart renders different output each time.

## Learning goals

- List the Helm value sources of an Application and put them in order of precedence.
- Predict the final value of a key that two or more sources set.
- Write `valueFiles`, `valuesObject`, `parameters` and `releaseName` in an Application.
- Explain what `ignoreMissingValueFiles`, `skipCrds` and `forceString` change.
- Explain how Helm hooks map to Argo CD hooks and why random template functions cause permanent drift.
- Say why a chart that writes its own namespace ignores the destination namespace.

## What to know first

You need to know that Argo CD renders a chart with `helm template` and applies the manifests itself. The seed chart in `chart` has the defaults `replicas: 2` and the image `docker.io/library/python:3.13-alpine`, and a second file `values-prod.yaml` with `replicas: 3`. The Deployment and Service of the chart are both called `git-probe` and name the namespace `starfleet` themselves.

## Reading order

The first part explains the value sources and their precedence, and a graded lab follows it. The second part covers the release name, the namespace, custom resource definitions, hooks and non-deterministic templates. The third part walks through layered values and a missing values file in the playground. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

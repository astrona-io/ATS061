---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Kustomize Overrides And Inspecting Rendered Output

A Kustomize overlay fixes the differences between environments in Git. Sometimes the Application needs a change that does not belong in Git: a pinned image, an owner annotation or a patch for one cluster. Argo CD lets the Application carry those changes. This module explains the Kustomize settings of an Application, how they combine with the overlay, and how to inspect and debug the rendered output.

## Learning goals

- Write `spec.source.kustomize` with `images`, `replicas`, `namePrefix`, `commonLabels`, `commonAnnotations` and `patches`.
- Predict which value wins when the overlay and the Application both set it.
- Explain why a common label can change a selector, and what `labelWithoutSelector` and `forceCommonLabels` do.
- Compare the rendered manifests with the live objects and with the Git revision.
- Diagnose a render failure from the `ComparisonError` condition and fix it.
- Explain why pinned revisions, stable inputs and protected values matter for rendering.

## What to know first

You need to know that Argo CD builds the directory named by `path` with `kustomize build`, and what an overlay and a base are. The seed repository has the base in `kustomize/base` and the overlays `kustomize/overlays/dev` and `kustomize/overlays/prod`. Both overlays add a name prefix and a label. The `dev` overlay runs one replica, and the `prod` overlay runs three replicas with the image tag `3.12-alpine`.

## Reading order

The first part covers the Kustomize settings of an Application and how they combine with an overlay, and a graded lab follows it. The second part covers how to inspect rendered manifests, diagnose render failures and keep rendering reproducible and safe. The third part walks through overrides, a live difference and a broken path in the playground. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

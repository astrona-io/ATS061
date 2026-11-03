---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Helm And Kustomize As Argo CD Rendering Inputs

Most teams do not keep plain Kubernetes manifests in Git. They keep a Helm chart or a Kustomize directory and let a tool turn it into manifests. Argo CD supports both. This module explains who runs the tool, what the tool receives, what Argo CD does with the result and how to prove that the cluster matches the rendered output.

## Learning goals

- Explain that Argo CD renders a Helm chart with `helm template` and does not install a Helm release.
- Say which Argo CD component runs the rendering tool and which component compares the result with the cluster.
- Predict which tool Argo CD selects for a path, and name the files that decide it.
- Write an Application that points at a Helm chart and one that points at a Kustomize overlay.
- Read `status.sourceType`, `status.sync.revision` and `status.summary.images` to see what Argo CD rendered.
- Explain why a rendered resource keeps its own namespace and why a name prefix changes the name of every object.

## What to know first

You need to know what an Application is, what the desired state in Git means and how a sync applies it. The playground has Argo CD and a Git server inside the cluster. The seed repository holds a Helm chart in `chart`, a Kustomize base in `kustomize/base` with the overlays `kustomize/overlays/dev` and `kustomize/overlays/prod`, and plain manifests in `plain` and `workloads`.

## Reading order

The first part explains the rendering mechanism and covers Helm charts, and a graded lab follows it. The second part covers Kustomize bases and overlays, and a second graded lab follows it. The third part walks through both tools in the playground. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

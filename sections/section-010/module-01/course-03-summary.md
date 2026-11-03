---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Summary

Argo CD keeps a cluster equal to a description stored in Git. The description is not used as it is. The repository server clones the requested revision, renders the directory into plain Kubernetes manifests, and those manifests are the desired state. The application controller compares them with the live resources from the Kubernetes API server and records the result on the Application object.

An Application is a custom resource with a few fixed fields: the repository URL, the target revision, the path, the destination cluster and namespace, and the project. A branch moves with new commits, while a tag or a commit hash stays fixed. Argo CD marks every resource it creates with the tracking annotation `argocd.argoproj.io/tracking-id`, which starts with the Application name, so it always knows which live resources belong to which Application.

Two statuses answer two questions. Sync status says whether live equals desired, with the values `Synced`, `OutOfSync` and `Unknown`. Health status says whether the resources work, with values such as `Healthy`, `Progressing` and `Degraded`. The four combinations carry different meaning: `Synced` and `Degraded` points to the workload, `OutOfSync` and `Healthy` points to drift, and `Unknown` points to a source that could not be rendered.

Drift comes from manual changes in the cluster or from new commits. A sync applies the desired state, started either by a person or by automated sync. Pruning deletes live resources that left the source, and self-healing reverts manual changes. Both are separate switches under `spec.syncPolicy.automated` and both are off until you set them.

When a step fails, diagnose in the order of the loop: source, rendering, comparison, application, health. The failure signature tells you which component to look at.

<!-- astrona:playground:destroy -->

---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Render A Helm Source In Argo CD

Reconcile the declared application from the internal Git source.

The task and solution use a separate pinned kind cluster. Run `testing/smoke.sh` with its private kubeconfig to verify initial rejection and reference success. Static validation is not live evidence. Runtime verification remains pending.

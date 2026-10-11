---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Summary

Argo CD uses supported Helm or Kustomize input to generate desired Kubernetes resources, then manages their reconciliation. Helm rendering in this model is distinct from using Helm as the deployment release manager.

Values, overlays and identity transformations affect the generated contract. Deterministic output, protected inputs and reviewed diffs are essential because valid source files can still render incorrect namespaces, labels, references or authority.

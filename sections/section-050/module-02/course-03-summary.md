---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Summary

The app-of-apps pattern uses one parent Application whose Git path holds manifests of kind `Application`. The parent syncs these manifests into the namespace `argocd`, and the application controller reconciles each new child Application like any other. The parent owns only the child Application objects. Each child owns its own workloads, and Argo CD records the owner of every object in the annotation `argocd.argoproj.io/tracking-id`.

Because the parent compares the child objects, it repairs them. With self-heal on, an edited child goes back to the manifest in Git, and a deleted child is created again. With prune on, a child whose manifest leaves Git is removed. The finalizer `resources-finalizer.argocd.argoproj.io` decides whether removing an Application also removes the resources it created. Without the finalizer the workloads stay behind and have no owner. Sync waves on the child manifests order the start of the children, and the health of the parent reflects the health of its children.

To diagnose a problem, start at the parent. A parent that cannot render its path shows a `ComparisonError` and creates no children. A child that exists but fails shows its own status, and a child that is synced but degraded points to its workloads. Only people who may create Applications in any project should have write access to the path of a parent.

- The parent owns the child Application objects, and each child owns its workloads.
- Self-heal and prune on the parent repair and remove children.
- The finalizer controls whether workloads go with their Application.

<!-- astrona:playground:destroy -->

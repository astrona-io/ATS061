---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Summary

Argo CD separates finding a difference from removing it. The application controller compares the desired manifests with the live objects and stores the result in `status.sync.status`. A sync is a separate operation that applies the desired state and records its phase, message and per-resource result in `status.operationState`.

A person or a tool starts a manual sync. The controller starts an automated sync when the Application has `syncPolicy.automated` and is `OutOfSync`. It starts at most one automated sync for the same commit and parameters, and it does not retry a failed one unless a retry policy or self-heal gives it a reason.

Prune and self-heal are two independent switches inside `automated`, and both default to off. Prune lets automation delete tracked objects that Git no longer declares. A built-in guard stops a prune that would empty the whole Application unless `allowEmpty` is set, and the annotation `argocd.argoproj.io/sync-options: Prune=false` protects one object. Self-heal lets automation revert live changes to declared fields, which makes manual hotfixes disappear unless they are committed to Git.

- Compare and sync are different operations.
- Automated sync needs `OutOfSync` and does not repeat a failed attempt for the same commit.
- `prune` controls deletion, `selfHeal` controls reverting live changes.
- Rollback is not allowed while automated sync is enabled.

<!-- astrona:playground:destroy -->

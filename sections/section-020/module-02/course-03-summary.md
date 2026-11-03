---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Summary

One sync operation orders objects by phase, then by wave, then by kind and name. The phases are PreSync, Sync, PostSync and SyncFail. A hook is a manifest with the annotation `argocd.argoproj.io/hook` that runs in a phase, and its delete policy decides when the hook object is removed. The annotation `argocd.argoproj.io/sync-wave` sets an integer wave, the default is `0`, and Argo CD waits for health between waves.

Hooks do not run during a selective sync. A failed PreSync hook stops the sync and starts the SyncFail hooks, and a failure in a later wave leaves the earlier waves applied.

Sync options change how objects are applied and deleted. They live in `spec.syncPolicy.syncOptions` or in the annotation `argocd.argoproj.io/sync-options` on a single object. `CreateNamespace=true` creates the namespace, `ApplyOutOfSyncOnly=true` limits the apply set, `ServerSideApply=true` avoids annotation-size and ownership conflicts, `PruneLast=true` prunes after everything else, and `Prune=false` and `Delete=false` protect single objects. `Replace=true` and `Force=true` are destructive.

- Order is phase, wave, kind, name.
- Waves are strings in annotations and negative values are allowed.
- Choose an option for a known failure, not by habit.

<!-- astrona:playground:destroy -->

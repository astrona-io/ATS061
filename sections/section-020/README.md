---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Synchronize Applications Using Argo CD

This section teaches how Argo CD moves an Application from the state in Git to the state in the cluster, and how you control that move. It covers manual and automated sync, pruning and self healing, the order of objects inside one sync with phases, waves and hooks, sync options, retries, sync windows and the deployment history with rollback. Three modules each end with a playground exercise and a graded lab, and a capstone lab combines them.

## Learning Outcomes

After this section you can:

- Explain the difference between comparing an Application and syncing it, and start a manual sync.
- Configure automated sync with `prune`, `selfHeal` and `allowEmpty`, and say what each one changes.
- Order objects with sync phases and waves, and write hooks with a delete policy.
- Choose sync options such as `CreateNamespace=true`, `PruneLast=true`, `ApplyOutOfSyncOnly=true` and `ServerSideApply=true` for a known failure.
- Set a retry policy with a limit and a backoff, and calculate the wait before each attempt.
- Write an AppProject sync window and predict which syncs it blocks.
- Read the deployment history and roll back an Application, and explain why the Application is then `OutOfSync`.

## Learning Path

| Module | Topic | Graded lab |
| --- | --- | --- |
| 1 | Manual and automated sync, pruning and self healing | Repair live drift with self healing |
| 2 | Sync phases, waves, hooks and options | Sync an ordered Application with hooks and options |
| 3 | Sync retries, sync windows, rollback and history | Freeze automated syncs and roll back a release |
| Capstone | All three modules | Run a controlled release of the fleet |

Each module has a landing page, its lessons, a summary and a private playground. Labs use a separate environment with Argo CD 3.5.4 and a disposable Git server inside the cluster. The section ends with a quiz of 12 questions.

All labs and playgrounds in this section are UNTESTED: they were validated statically and never booted.

---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Manual And Automated Sync, Pruning And Self-Healing

An Argo CD Application can show that the cluster differs from Git, but a difference alone changes nothing. Something has to apply the Git state to the cluster. That step is a sync, and Argo CD lets you start it by hand or let the application controller start it for you. This module explains what a sync does, when automation starts one, and which two extra switches, prune and self-heal, decide what automation is allowed to delete and to undo.

## Learning goals

- Explain the difference between comparing an Application and syncing it.
- Start a manual sync and read the operation state it produces.
- Describe the conditions under which automated sync starts and when it does not.
- Say what `prune` and `selfHeal` each change, and why both default to off.
- Repair live drift by letting self-heal restore the declared replica count.

## What to know first

You need to read an Application's `status.sync.status` and `status.health.status`, and to know that the `source` of an Application names a Git path. The playground is a `kind` cluster with Argo CD installed in the `argocd` namespace and a small Git server inside the cluster. The Git server holds a `plain` path that declares a `git-probe` Deployment with two replicas and a `git-probe` Service for the `starfleet` namespace. No Application exists yet; you create them.

## Reading order

The first part follows one sync from the comparison to the applied resources and compares manual with automated sync. The second part covers pruning and self-healing: what each does, what stops them and how to switch them off for one resource. The third part is a guided walk through the playground, after which a graded lab asks you to repair live drift. The summary closes the module.

Launch the playground now and keep it next to you while you read:

<!-- astrona:playground -->

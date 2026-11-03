---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Sync Retries, Sync Windows, Rollback And History

A sync does not always succeed on the first try, and it must not always run at the moment Git changes. Argo CD gives you three controls for this. A retry policy repeats a failed sync, a sync window decides when syncs may run at all, and the deployment history lets you return to an earlier revision when a release goes wrong. This module explains how each control works and what the Application shows while it applies.

## Learning goals

- Configure `spec.syncPolicy.retry` with a limit and a backoff, and calculate the wait before each attempt.
- Explain why automated sync does not retry a failed sync of the same commit by itself.
- Write an AppProject sync window of kind `allow` or `deny`, with a cron schedule, a duration and selectors.
- Say which syncs a window blocks and what `manualSync` changes.
- Read `status.history`, choose an entry and roll back to it.
- Explain why a rollback needs automated sync to be off and why it is a temporary measure.

## What to know first

You need to know what an Application is, what a sync operation is and how automated sync decides to start one. The playground has Argo CD and a Git server inside the cluster. The seed repository has a branch `main`, a branch `release` where the `plain` path has three replicas, the path `plain` with the Deployment and Service `git-probe`, the paths `workloads/alpha`, `workloads/beta` and `workloads/gamma`, and the path `broken/unknown-kind`, whose sync always fails.

## Reading order

The first part covers retries and the backoff calculation. The second part covers sync windows and how they interact with automated and manual syncs. The third part covers the deployment history and rollback. The fourth part walks through all three controls in the playground and ends with a graded lab. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

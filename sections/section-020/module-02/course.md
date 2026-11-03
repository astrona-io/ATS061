---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Sync Phases, Waves, Hooks And Options

A real application is rarely one object. A database migration must finish before the new version starts, a namespace must exist before the objects in it, and a notification should go out only after the application is healthy. Argo CD handles this order inside one sync operation. This module explains how a sync orders resources, how hooks run extra jobs at defined points, and how sync options change how each object is applied.

## Learning goals

- Name the sync phases and say when each one runs.
- Order resources with the `argocd.argoproj.io/sync-wave` annotation.
- Write a hook Job and choose its delete policy.
- Choose sync options such as `CreateNamespace=true`, `PruneLast=true`, `ApplyOutOfSyncOnly=true` and `ServerSideApply=true`.
- Read the result of each resource and hook from the operation state.

## What to know first

You need to know what a sync operation is and where its result is stored. The playground has Argo CD and a Git server inside the cluster. The path `waves` of the seed repository holds a ConfigMap `wave-config` in wave `-1`, a Deployment and a Service named `wave-app`, a PreSync hook Job `wave-presync` and a PostSync hook Job `wave-postsync`.

## Reading order

The first part covers phases, waves and hooks and how Argo CD decides the order. The second part covers sync options at the Application level and at the single object level, and ends with a graded lab that syncs the `waves` path with the right options. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

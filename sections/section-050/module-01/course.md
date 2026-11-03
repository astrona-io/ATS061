---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Drift, Refresh, Ignore Rules And Reconciliation Patterns

An Argo CD Application is only useful while its cluster matches the source in Git. Two things can break that match: someone changes the cluster by hand, or someone changes Git. Argo CD detects both, but it reacts in different ways, and some changes in the cluster are expected and must not count as errors. This module explains how Argo CD notices a difference, what a refresh is, why a refresh is not a sync, and how to tell Argo CD that one field belongs to another controller.

## Learning goals

- Explain what the refresh operation does and why it does not change the cluster.
- Name the triggers that make Argo CD compare Git with the cluster: a timer, a change event, a webhook and a manual refresh.
- Tell live drift from a source-driven update, and say which one self-heal reacts to.
- Write an `ignoreDifferences` entry with a group, a kind and a JSON pointer.
- Explain what `RespectIgnoreDifferences=true` adds to a sync.
- Say why a broad ignore rule can hide a real change.

## What to know first

You need to know what an Application is, what the sync status values `Synced` and `OutOfSync` mean, and how to read a Deployment with `kubectl`. The playground has Argo CD and a Git server inside the cluster. The seed repository has the path `plain` on the branch `main`, with the Deployment and Service `git-probe` in the namespace `starfleet`. The Deployment has two replicas.

## Reading order

The first part covers refresh, comparison and the difference between drift and a new commit. The second part covers ignore rules, the fields that other controllers own, and the sync option that makes a sync respect those rules. The third part applies both in the playground and ends with a graded lab. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

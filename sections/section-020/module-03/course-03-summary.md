---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Summary

A failed sync operation ends in the phase `Failed` unless the Application has a retry policy. The block `spec.syncPolicy.retry` sets a `limit`, where `-1` means no limit, and a `backoff` with a base `duration`, a `factor` and a `maxDuration`. The wait before each attempt grows by the factor and never exceeds the maximum. Automated sync starts one operation for each commit and set of parameters, so it does not start a new one for a commit that already failed. The retry policy repeats the same operation, and a new commit starts a new attempt.

A sync window is an entry in `spec.syncWindows` of an AppProject. It has a kind, `allow` or `deny`, a cron schedule, a duration and selectors for Applications, namespaces and clusters. With no matching window every sync is allowed. A matching `allow` window permits syncs only while it is active, a matching `deny` window blocks syncs while it is active, and `deny` wins over `allow`. Windows affect manual and automated syncs, and `manualSync: true` lets manual syncs through. A blocked Application is still compared with Git and shows `OutOfSync`.

Every successful sync adds an entry to `status.history` with an id, a revision and a time. The field `spec.revisionHistoryLimit` limits how many entries Argo CD keeps. A rollback syncs the Application to the revision of one entry, and it is refused while automated sync is on. The rollback changes only the cluster. Git still holds the newer commit, so the Application shows `OutOfSync` afterwards, and the lasting fix is a commit in Git.

- Retries repeat a failed operation. They do not change the commit.
- Windows decide whether a sync may start. They do not change the sync.
- Rollback needs automated sync off and leaves the Application out of sync with Git.

<!-- astrona:playground:destroy -->

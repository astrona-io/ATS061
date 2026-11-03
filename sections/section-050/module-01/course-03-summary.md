---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Summary

Argo CD builds a target state from Git in the repository server and reads the live state from the cluster in the application controller. A refresh compares the two and updates `status.sync.status`. It never changes the cluster. The comparison runs on a timer of 120 seconds plus jitter, on change events of the managed objects, on webhooks and on request, and a hard refresh also drops the cached manifests. A sync is the separate operation that applies the target state.

A difference has one of two origins. A new commit changes the target state and needs a sync. A hand edit in the cluster is live drift, and only automated sync with self-heal reverts it without a person. Fields that only the cluster writes, such as `status`, do not count as a difference, and neither does an extra field that Git does not declare.

Some fields belong to another controller. The block `spec.ignoreDifferences` removes them from the comparison by JSON pointer, jq path expression or field manager. By default the rule affects only the comparison, so a sync still overwrites the field. The sync option `RespectIgnoreDifferences=true` makes the sync keep the live value as well, except on the first sync of an object that does not exist yet. A narrow rule documents the owner of one field. A broad rule hides real changes such as a new image.

- A refresh compares and a sync applies.
- Self-heal reacts to live drift, and a new commit is a source-driven change.
- Scope an ignore rule to one kind and one field, and add the sync option when the sync must keep the live value.

<!-- astrona:playground:destroy -->

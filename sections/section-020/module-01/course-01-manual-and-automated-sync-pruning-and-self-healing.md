---
draft: true
exam_objectives:
- Synchronize Applications Using Argo CD
---
# Manual And Automated Sync, Pruning And Self-Healing

Argo CD can compare desired and live resources without changing them. Synchronization is the operation that attempts to apply the desired state. Manual and automated synchronization determine how that operation is initiated, while pruning and self-healing govern additional consequences. These decisions should be reviewed independently.

## Comparison Does Not Apply Changes

An OutOfSync result identifies a difference under the comparison model. It does not mean Argo CD has already changed the destination. A manual synchronization requires an authorized operation, while automated policy can initiate eligible changes under its supported behavior.

Automation depends on successful source retrieval, rendering and destination access. A desired revision can be known yet impossible to apply because an admission policy rejects a resource. Review the operation's actual error rather than assume every OutOfSync condition is an unavailable Git repository.

## Pruning Has Data Consequences

Pruning removes tracked live resources that are absent from the desired resource set under the applicable settings. It should be deliberate because deletion can affect storage, external resources or application availability. An empty render caused by a configuration mistake must not be treated casually as proof that every application resource should disappear.

Supported safeguards and per-resource options can influence deletion behavior. Their exact semantics depend on the intended version and resource lifecycle. Removing a resource from Git and deleting its backend data are not universally identical events, so review finalizers, reclaim policies and external ownership.

## Self-Healing Addresses Live Drift

Self-heal can restore differences introduced directly in the cluster under the automated synchronization model. It is distinct from enabling pruning and from reacting to a new source revision. A manually edited field can therefore be restored even when the reviewer believes no new Git commit occurred, if the applicable policy supports that behavior.

Emergency edits need a durable source decision. Either update the reviewed source or deliberately adjust the automation within an approved operational process. An unrecorded live fix can disappear on later reconciliation and leave responders unable to explain the change.

## Ordering And Hooks Are Not Transactions

Sync phases, hooks and waves can express ordering and operational work around delivery. A lower wave can need acceptable progress before later work proceeds. Hook Jobs have their own permissions, cleanup and side effects. A migration hook that writes to a database is not automatically rolled back when a later workload fails.

Ordering can coordinate dependencies, but it does not guarantee useful application behavior or atomic replacement of every resource. Failures can leave partial changes. Recovery needs to understand what was applied and which external effects occurred.

## Recovery Must Match Source Ownership

A rollback to an earlier resource version can conflict with the current desired revision. Automated reconciliation may restore the newer state unless source or policy is changed deliberately. Historical templates also do not necessarily preserve current Secrets, data schema or external dependencies.

For a failed delivery, distinguish source generation, apply failure, resource health and business outcome. Verify the intended state after correction and retain operation evidence. Synchronization is a controlled reconciliation step, not universal proof that every user request, migration and cleanup action succeeded.

## Common pitfalls

> [!WARNING]
> Automated sync, pruning and self-heal are separate decisions. Hooks and waves do not create atomic transactions, and a live rollback can conflict with unchanged desired source.

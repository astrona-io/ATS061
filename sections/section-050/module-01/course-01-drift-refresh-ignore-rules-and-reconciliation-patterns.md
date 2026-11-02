---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Drift, Refresh, Ignore Rules And Reconciliation Patterns

Argo CD reconciliation has several operations and ownership layers. A refresh obtains or updates comparison information, synchronization applies desired state, and automated policy determines when particular changes are attempted. Understanding those distinctions helps diagnose drift and avoid conflicting manual edits or controllers.

## Refresh Is Not Synchronization

A refresh can update Argo CD's view of source and live state under the supported cache behavior. It does not inherently mean resources were applied. A fresh OutOfSync result is comparison evidence. A synchronization operation then attempts the desired change with its own permissions, ordering and failure conditions.

Source updates and live changes can create different triggers. A new Git revision can change desired state, while a direct cluster edit can create drift from an unchanged source. Self-heal behavior is a separate automated policy choice. State which relationship changed before deciding whether automation should act.

## Controllers Own Different Fields

Kubernetes controllers update status and can manage other fields according to their contracts. Mutating admission or autoscaling can also affect effective resources. A desired-state comparison needs to account for legitimate field ownership without hiding every difference.

Ignore-difference settings can exclude selected comparison details. They are useful when a justified controller owns a field, but broad exclusions can conceal changed privileges, image references or routing intent. Comparison exclusions and synchronization behavior are not always identical; supported settings determine whether ignored fields also affect apply operations.

## Bootstrap Composition Adds Ownership

An app-of-apps pattern uses an Application to manage other Application resources. It can organize cluster bootstrap and shared components, but the parent has authority over its children. A manual child edit can be restored if the parent source still describes another value.

ApplicationSet generates Applications from supported inputs and templates. Its controller adds another reconciliation layer. The generated Application then reconciles its own workloads. Diagnose generation and application delivery separately so a missing child is not mistaken for an application runtime failure.

## Avoid Competing Sources Of Truth

Two Applications or another automation system managing the same object can continually overwrite each other. A live emergency edit can also conflict with Git-owned intent. Define a single intended ownership model or a carefully scoped field-sharing contract rather than rely on whichever controller writes last.

For example, an autoscaler-managed replica count can need deliberate comparison and apply treatment. Ignoring every Deployment difference to suppress that one expected change would hide unrelated drift. Narrow the exception and document the responsible controller and desired behavior.

## Diagnose The First Failed Layer

If an Application is absent, inspect its generator or parent. If it exists but cannot render source, inspect repository and generation inputs. If it renders but cannot sync, inspect destination operations. If it is synced but unhealthy, inspect native resources and application dependencies.

Cache refresh can clarify stale evidence, but it cannot repair an invalid source or denied API operation. Similarly, a manual sync cannot fix every business error. Preserve the distinction between updated observation and changed state. Reconciliation becomes predictable when ownership, comparison exceptions and automation triggers are explicit and reviewable.

## Common pitfalls

> [!WARNING]
> Refresh does not automatically apply resources. Broad ignore rules can hide real drift, and generated child Applications can be restored by their parent ownership even after direct edits.

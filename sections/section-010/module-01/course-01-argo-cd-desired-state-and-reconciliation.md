---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Argo CD Desired State And Reconciliation

Argo CD implements declarative application delivery by comparing desired resources from a configured source with live resources in a destination cluster. It can report drift and synchronize state under an Application's policy. Its role is distinct from building images, running every native controller or proving that an application serves correct business results.

## Desired State Is Rendered Input

A source can contain plain manifests or supported configuration such as Helm or Kustomize. Argo CD obtains the selected revision and renders the intended Kubernetes resources. The repository path, chart settings and values determine the resulting resource set. A Git commit exists before rendering and does not automatically constitute a valid deployable definition.

The desired state should be reproducible. A template generating random values can render a different result on successive comparisons and cause persistent drift. External mutable inputs can also change output without the reviewer expecting it. Record the source and rendering contract rather than assume a repository name alone identifies exact desired resources.

## Live State Is A Different View

Kubernetes stores current resources and their observed state. Argo CD compares relevant live definitions with desired definitions, accounting for its supported tracking and comparison behavior. Native controllers still manage replicas, placement and status under their own responsibilities.

A Deployment matching its desired spec can still have no ready replicas because an image cannot be pulled. Argo CD's alignment comparison is therefore different from the controller's application readiness evidence. The same distinction applies to external dependencies that the Kubernetes resources do not fully describe.

## Sync Status And Health Answer Different Questions

Sync status describes whether the compared resources align with desired state. Health describes observed conditions under supported resource-health assessment. A Synced Application can be unhealthy, while a resource can be healthy but differ from the declared source. Those combinations are useful clues rather than contradictions.

A health assessment itself has limits. Custom resources may need appropriate health interpretation, and a healthy Kubernetes resource does not prove every business transaction succeeds. Application metrics, logs and user-facing checks provide complementary evidence where needed.

## Components And Permissions Form The Path

Repository access and manifest generation have their own dependencies. Application reconciliation needs access to the intended destination cluster and authority for the resources involved. The API and UI expose management and observation paths, while controllers perform reconciliation. Failure in one path should not be attributed automatically to every other component.

A missing repository credential can prevent desired-state retrieval while existing workloads continue running. A denied destination operation can block synchronization despite successful rendering. Diagnose source, rendering, comparison and application in order.

## Decide How Drift Should Be Resolved

A manual live edit can produce drift from the source of truth. Depending on policy, Argo CD may report it or restore desired state. An emergency change should have a deliberate path back into reviewed source so later reconciliation does not silently undo the intended correction.

Automation should preserve narrow source and destination permissions. A repository writer can influence delivered workload authority, so review that trust boundary along with API credentials. GitOps makes the intended relationship explicit; it does not make every source change safe or every reconciliation outcome correct.

## Common pitfalls

> [!WARNING]
> Synced and Healthy are different states. Source retrieval, deterministic rendering, destination authority and native resource behavior must be assessed separately.

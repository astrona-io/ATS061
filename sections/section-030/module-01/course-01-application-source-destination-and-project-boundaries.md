---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Application Source, Destination And Project Boundaries

The Argo CD Application resource identifies a unit of declarative delivery. Its specification connects desired source content with a destination cluster, a project and synchronization behavior. Reading those relationships together helps prevent deployment into the wrong environment or reconciliation of a broader resource set than intended.

## Source Selects What Is Rendered

A source includes a repository or other supported location, a target revision and the path or chart relationship used for generation. Helm and Kustomize settings can further specialize the rendered output. A repository URL alone does not identify the intended resource set.

A mutable branch or tag can change the content selected by later reconciliation. An immutable commit or otherwise controlled version provides a more specific reference where the workflow requires it. The selected revision still needs valid rendering and trustworthy source ownership. Pinning content does not establish that the content is safe.

## Destination Selects Where It Goes

The destination identifies a cluster and namespace under the supported Application schema. A namespace default for namespaced resources does not necessarily rewrite every explicit namespace or constrain every cluster-scoped resource. Review the rendered objects and project rules rather than assume one destination field limits all possible effects.

The cluster access configured for Argo CD needs appropriate authority. A correct source with the wrong destination can cause a serious scope error, while the correct destination with insufficient permissions can fail application. Context and ownership should be visible in review.

## Projects Add Governance

AppProject can restrict allowed sources, destinations and resource kinds under its supported policy model. It can also organize access and operational boundaries. Those restrictions complement Kubernetes authorization at the destination. Neither should be described as universally replacing the other.

A source writer can influence workloads delivered with the Application's authority. Restricting a destination while permitting arbitrary source mutation can still allow harmful behavior within that scope. Review who may change the Application, project and referenced source, as well as who may initiate synchronization.

## Tracking Establishes Ownership Context

Argo CD tracks resources associated with an Application using its configured model. That affects comparison, pruning and status. Shared resources or conflicting ownership can complicate reconciliation. Two Applications should not unintentionally fight over the same object without a deliberate ownership design.

An object present in the namespace is not automatically part of every Application there. Conversely, a tracked cluster-scoped resource can have effects beyond that namespace. Review the actual rendered and tracked set when interpreting a difference or deletion plan.

## Lifecycle Requires Deliberate Deletion

Deleting an Application can interact with finalizers and cascading resource deletion according to configuration. Removing the management object and removing all managed workloads are different intended operations. Storage and external resources can retain or destroy data under their own policies.

Status then provides evidence about source comparison, synchronization and resource health. It should be interpreted alongside the exact spec and observed generation. A useful Application definition makes source, destination, governance and lifecycle explicit so a reviewer can assess both intended delivery and its possible authority.

## Read The Application Relationship

```yaml
spec:
  project: payments
  source:
    repoURL: repository-location
    targetRevision: reviewed-release
    path: environments/production
  destination:
    name: in-cluster
    namespace: payments
```

This illustrative spec fragment binds a source path and revision to a destination under a project. The repository-location value stands for the organization’s approved repository URL; the fragment is deliberately non-operational. Project permissions, source rendering and destination credentials are separate prerequisites; this is not a complete deployable Application.

## Common pitfalls

> [!WARNING]
> Repository, revision, path and destination are different selectors. AppProject restrictions do not replace Kubernetes RBAC, and a destination namespace is not a universal boundary on every rendered resource.

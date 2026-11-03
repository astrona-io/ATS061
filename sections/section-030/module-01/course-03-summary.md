---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Summary

An Argo CD Application selects Git content with `repoURL`, `targetRevision` and `path`, and a cluster and namespace with `destination`. The repo server renders the source and resolves the revision to a commit SHA in `status.sync.revision`. The application controller compares the rendered manifests with the live objects. A branch or tag can move, so the commit SHA is the proof of what was deployed.

The destination namespace is a default for objects whose manifests have no namespace. It does not rewrite a namespace that a manifest sets. A destination names the cluster by `server` URL or by `name`, and an Application uses one of the two.

An AppProject limits what its Applications may use. The field `sourceRepos` limits repositories, `destinations` limits cluster and namespace pairs, and four lists limit cluster-scoped and namespaced kinds. The project `default` allows everything. Argo CD checks an Application against its project on every reconciliation and reports a refusal as a condition of type `InvalidSpecError` in `status.conditions`, before any object reaches the cluster. A project narrows what Applications may request. It does not give Argo CD rights in Kubernetes and does not replace Kubernetes authorization.

- Read `status.sync.revision`, not `targetRevision`.
- A merge patch replaces a whole list in a project.
- `default` is permissive and restricts nothing.

<!-- astrona:playground:destroy -->

---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Summary

Argo CD turns a Git directory into manifests in the repository server and compares them with the cluster in the application controller. The rendering tool comes from the Application when it sets a tool block, and otherwise from the files in the directory: `Chart.yaml` selects Helm, a `kustomization.yaml` selects Kustomize and anything else is read as plain YAML. The field `status.sourceType` records the choice.

Argo CD uses Helm only to render. It runs `helm template` with the Application name as the release name and the destination namespace as the namespace, and it applies the objects itself. No Helm release Secret exists, so Helm commands that act on releases do not apply. A rendered object keeps a namespace that its manifest names, and the destination namespace only fills in the gaps.

Kustomize builds the directory named by `path`. An overlay refers to a base and changes names with a prefix, adds labels and sets replicas or image tags. The base stays unchanged, the path decides which result reaches the cluster, and the object names include any prefix.

Rendering and health are different facts. `status.sync.status` compares the rendered manifests with the cluster, and `status.health.status` reports whether the objects work. The fields `status.sync.revision` and `status.summary.images` show which commit and which image the render produced.

- Helm is a renderer here, not a release manager.
- A single `kustomization.yaml` in a directory selects Kustomize.
- The path selects the overlay, and the overlay selects names, labels, replicas and tags.

<!-- astrona:playground:destroy -->

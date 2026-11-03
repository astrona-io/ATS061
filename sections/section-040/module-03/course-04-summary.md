---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Summary

The block `spec.source.kustomize` of an Application changes the Kustomize build without a commit. It can set a name prefix or suffix, image overrides, replica counts, common labels and annotations, a namespace, inline patches and components. Argo CD applies these settings to the kustomization before it runs the build, so a value from the Application replaces the same key in the overlay. The overlay in Git stays unchanged, and another Application that uses the overlay is not affected.

Names in replica overrides and in patches are the names in the base, not the prefixed names. A patch also needs the namespace of its target when the base sets one. Common labels reach selectors unless `labelWithoutSelector` is true, and a Deployment selector cannot change after creation, so a new common label can break a sync of a live Deployment. A label key that already exists makes the build fail unless the force flag is set.

The rendered manifests are the evidence of what the tools produced. The command `argocd app manifests` prints them, and `argocd app diff` shows the difference from the live objects. The status of the Application records the commit, the tool and the images of the last render. A hard refresh drops cached manifests and renders again.

A failed render appears as the condition `ComparisonError` with the sync status `Unknown`, and it leaves the live objects as they are. Reproducible output needs a pinned revision such as a tag or a commit hash, pinned remote inputs and templates without random or time-based values. Secrets stay out of values, parameters, patches and manifests in Git, because everyone who can read them can read the secret.

- Application overrides beat the overlay, and the overlay beats the base.
- A render error is not a sync error: the cluster keeps its old objects.
- A branch is not a pinned revision, and base64 is not protection.

<!-- astrona:playground:destroy -->

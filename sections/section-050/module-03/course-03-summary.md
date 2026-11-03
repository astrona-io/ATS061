---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Summary

An ApplicationSet is a template plus one or more generators. The generators produce parameter sets: the list generator reads elements from the ApplicationSet itself, the cluster generator reads the clusters Argo CD knows, the Git generator reads directories or the content of files, and the matrix generator combines two generators. The template, usually with `goTemplate: true`, becomes one Application for each parameter set, and its name must be unique for every set.

The ApplicationSet controller does this work, and the application controller then reconciles the Applications. The ApplicationSet controller owns the generated Applications through owner references. It patches an edited Application back to the template, creates a deleted Application again while its parameter set exists, and deletes an Application when its parameter set disappears. The sync policy of the ApplicationSet can limit these powers. Deleting an ApplicationSet deletes its Applications, and by default their workloads go too, unless `preserveResourcesOnDeletion: true` is set.

App-of-apps keeps one full manifest in Git for each child and uses an ordinary Application as the parent, with ownership in the tracking annotation. An ApplicationSet keeps only inputs and a template, and uses owner references. App-of-apps fits a short list of different children. An ApplicationSet fits many variations of one pattern. When something is missing, read the layers in order: the ApplicationSet, the generated Application, then the workloads.

- The generator produces parameters and the template produces Applications.
- The ApplicationSet controller owns the Applications and the application controller owns the workloads.
- Change the template or the input, never the generated Application.

<!-- astrona:playground:destroy -->

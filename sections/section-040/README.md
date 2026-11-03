---
draft: true
exam_objectives:
- Configure Argo CD with Helm and Kustomize
---
# Configure Argo CD with Helm and Kustomize

This section teaches how Argo CD turns a Helm chart or a Kustomize directory into the manifests that it compares and applies, and how you control that rendering from the Application. It covers tool detection, Helm value sources and their precedence, release names, namespaces, hooks and deterministic output, Kustomize bases and overlays, overrides in the Application, and the commands that show rendered manifests and render failures. Three modules each end with a playground exercise and a graded lab, and a capstone lab combines them.

## Learning Outcomes

After this section you can:

- Explain that the repository server renders sources, that Argo CD uses Helm only as a template engine and that it creates no Helm release.
- Predict which tool Argo CD selects for a directory and read it from `status.sourceType`.
- Combine chart values, values files, `valuesObject` and parameters and predict which value wins.
- Explain how release names, destination namespaces, hooks and non-deterministic templates affect a render.
- Explain Kustomize bases and overlays, and override images, replicas, labels, annotations and patches from the Application.
- Print rendered manifests, read a difference and diagnose a `ComparisonError`.

## Learning Path

| Module | Topic | Graded lab |
| --- | --- | --- |
| 1 | Helm and Kustomize as rendering inputs | Render a Helm chart with a production values file, and deploy a Kustomize overlay |
| 2 | Helm values, parameters and release settings | Layer Helm values for the fleet chart |
| 3 | Kustomize overrides and rendered output | Override Kustomize overlays from two Applications |
| Capstone | All three modules | Repair and extend the fleet rendering setup |

Each module has a landing page, its lessons, a summary and a private playground. Labs use a separate environment with Argo CD 3.5.4 and a disposable Git server inside the cluster. The section ends with a quiz of 12 questions.

All labs and playgrounds in this section are UNTESTED: they were validated statically and never booted.

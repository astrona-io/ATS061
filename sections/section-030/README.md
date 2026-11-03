---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Use Argo CD Application

This section teaches how an Argo CD Application describes what to deploy, where to deploy it and under which rules. It covers the source and destination of an Application and the limits of an AppProject, plain directory, Helm and Kustomize sources with parameter overrides, ignored differences, resource tracking, finalizers and deletion, the app-of-apps pattern and Application health. Three modules each end with a playground exercise and a graded lab, and a capstone lab combines them.

## Learning Outcomes

After this section you can:

- Read the source, destination and project of an Application and say which part decides what is deployed and where.
- Restrict an Application with an AppProject by source repository, destination, namespaced kinds and cluster-scoped kinds, and diagnose a refusal.
- Tell how Argo CD chooses between a plain directory, Helm and Kustomize, and write the source fields of each.
- Override Helm values and Kustomize settings in the Application, and name the precedence between the Helm value sources.
- Write `ignoreDifferences` for an expected difference and say what the sync option `RespectIgnoreDifferences=true` adds.
- Read the tracking annotation of an object and say which Application owns it.
- Choose a finalizer for an Application, and predict what deleting the Application does to its workloads.
- Build an app of apps and read the health of an Application.

## Learning Path

| Module | Topic | Graded lab |
| --- | --- | --- |
| 1 | Application source, destination and project boundaries | Restrict an Application to one repository, namespace and kinds |
| 2 | Directory, Helm and Kustomize sources, overrides and ignored differences | Override a Helm chart and a Kustomize overlay and ignore replicas |
| 3 | Resource tracking, finalizers, app of apps and health | Build an app of apps and retire a scratch Application |
| Capstone | All three modules | Bring the bridge systems under Argo CD control |

Each module has a landing page, its lessons, a summary and a private playground. Labs use a separate environment with Argo CD 3.5.4 and a disposable Git server inside the cluster. The section ends with a quiz of 12 questions.

All labs and playgrounds in this section are UNTESTED: they were validated statically and never booted.

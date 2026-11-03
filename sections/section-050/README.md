---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Identify Common Reconciliation Patterns

This section teaches how Argo CD keeps the cluster equal to Git, what it does when the two differ, and which patterns teams use to manage many Applications. It covers refresh, comparison and drift, ignore rules for fields that other controllers own, the app-of-apps pattern and ApplicationSet generators. Three modules each end with a playground exercise and a graded lab, and a capstone lab combines them.

## Learning Outcomes

After this section you can:

- Explain what a refresh does, when Argo CD starts one, and why it never changes the cluster.
- Tell live drift from a change in Git and predict what automated sync and self-heal do with each.
- Write an `ignoreDifferences` rule for one field and explain why `RespectIgnoreDifferences=true` is needed for syncs.
- Build an app-of-apps parent, say who owns the children and the workloads, and predict what happens when a child is edited or deleted.
- Write an ApplicationSet with a list generator or a Git files generator and a Go template, and explain who owns the generated Applications.
- Choose between an app-of-apps parent and an ApplicationSet for a given fleet.

## Learning Path

| Module | Topic | Graded lab |
| --- | --- | --- |
| 1 | Drift, refresh and ignore rules | Scope an ignore difference exception |
| 2 | App-of-apps bootstrap | Bootstrap the fleet with an app of apps |
| 3 | ApplicationSet generators and templates | Generate environments with an ApplicationSet |
| Capstone | All three modules | Bring the station fleet under three reconciliation patterns |

Each module has a landing page, its lessons, a summary and a private playground. Labs use a separate environment with Argo CD 3.5.4 and a disposable Git server inside the cluster. The section ends with a quiz of 12 questions.

All labs and playgrounds in this section are UNTESTED: they were validated statically and never booted.

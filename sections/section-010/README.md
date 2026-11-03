---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Understand Argo CD Fundamentals

This section teaches what Argo CD does and how to read what it reports. It covers the reconciliation loop from a Git commit to an Application status, the components that perform each step, and the objects and status fields that describe the result. Three modules each end with a playground exercise and a graded lab, and a capstone lab combines them.

## Learning Outcomes

After this section you can:

- Explain desired state, live state, drift and reconciliation, and which Argo CD component does each step.
- Create an Application from a Git source with `kubectl`, and read its sync status, health status and operation state.
- Name the seven Argo CD components, say what each one changes and read their roles from the workloads and logs.
- Follow a refresh and a sync through the repository server, Redis and the application controller.
- Diagnose and repair an Application with a wrong source path or revision.
- Use the `argocd` client in core mode to list, read and diff Applications.
- Correct an Application that is `OutOfSync` or unhealthy by changing its source or sync policy.

## Learning Path

| Module | Topic | Graded lab |
| --- | --- | --- |
| 1 | Argo CD desired state and reconciliation | Deliver a Git sourced Application |
| 2 | Argo CD architecture and components | Repair an Application with a comparison error |
| 3 | Core concepts, application status and the CLI | Correct an OutOfSync and unhealthy Application |
| Capstone | All three modules | Repair, create and report on Applications |

Each module has a landing page, two lessons, a summary and a private playground. Labs use a separate environment with Argo CD 3.5.4 and a disposable Git server. The section ends with a quiz of 12 questions.

All labs and playgrounds in this section are UNTESTED: they were validated statically and never booted.

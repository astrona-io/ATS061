---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Starting Environment

Argo CD is installed in the `argocd` namespace and a Git server inside the cluster serves the path `plain` with the Deployment `git-probe`. No Application exists. The task is to create one Application whose ignore rule leaves the replica count to another controller and still repairs every other drift.

---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Constrain Application Source And Destination

Reconcile the declared application from the internal Git source.

## Starting state

Argo CD controllers are installed in argocd. The task uses a disposable internal Git source. No learner Application exists.

Use a host shell with the private kubeconfig for this independent kind environment. A kubeconfig identifies the cluster and credentials used by kubectl, the Kubernetes command-line tool.

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-lab-030-01-01)"
test "$(kubectl config current-context)" = "kind-astro-ats-061-lab-030-01-01" || exit 1
node_name="astro-ats-061-lab-030-01-01-control-plane"
worker_name="astro-ats-061-lab-030-01-01-worker"
```

Keep this connection selected. Host-level commands name only this environment's node containers. They do not operate on the host operating system.

## Required result

Allow only the private repository, starfleet destination, Deployment and Service resources in an AppProject. The Application must sync successfully inside that boundary.

## Verify The Result

The grader checks the required object fields and actual observations. Wait for controller convergence before submitting. Preserve the task's namespace, workload names and unrelated components.

---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Summary

An Application connects one source to one destination, and an AppProject limits what Applications may do: which repositories they read, which clusters and namespaces they deploy to and which resource kinds they create. The `default` project allows everything, so it protects nothing. The target state is what the repository server renders from the source. The live state is what the cluster holds. The application controller compares the two, and the result is the sync status.

An Application has two independent statuses. Sync status has the values `Synced`, `OutOfSync` and `Unknown`. Health status has the values `Healthy`, `Progressing`, `Degraded`, `Suspended`, `Missing` and `Unknown`, and the health of the Application is the worst health of its resources. `Synced` with `Degraded` means Argo CD applied exactly what Git says and the workload fails, so the manifest must change. `OutOfSync` with `Healthy` means a working workload differs from Git. `Unknown` means the comparison did not run.

A refresh repeats the comparison and updates the status. A hard refresh also discards the cached manifests and cluster state. Neither changes the cluster. Argo CD tracks ownership with the annotation `argocd.argoproj.io/tracking-id`, whose value has the form `application:group/kind:namespace/name`. The tracking method can also use the label `app.kubernetes.io/instance`. A sync is an operation, and `status.operationState` records the phase of the last one, which can be `Running`, `Succeeded`, `Failed`, `Error` or `Terminating`. It describes the past, not the present.

The `argocd` client with the flag `--core` reads the Application objects through the kubeconfig and the namespace of the current context, without a login and without the API server. `argocd app list` and `argocd app get` show the statuses and the resource table, `argocd app diff` shows the difference between live and target state and exits with 1 when there is one, and `--refresh`, `--hard-refresh` and `--show-operation` add a refresh or the operation state. To repair an unhealthy or out-of-sync Application, read both statuses, find the resource, find the cause, correct the source or the sync policy, and let Argo CD apply it. A change made by hand in the cluster is not a repair.

<!-- astrona:playground:destroy -->

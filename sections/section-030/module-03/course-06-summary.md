---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Summary

Argo CD marks every object it applies. The default method writes the annotation `argocd.argoproj.io/tracking-id` with the form `application:group/Kind:namespace/name`, and the setting `application.resourceTrackingMethod` selects the method. The controller selects the objects of an Application by this marker. It compares and prunes only marked objects, so a hand-made object in the same namespace stays out of the Application. Two Applications that render the same object conflict and raise a shared resource warning.

The finalizer `resources-finalizer.argocd.argoproj.io` makes the controller delete the managed objects before the Application is removed, with foreground propagation. The variant with `/background` uses background propagation. Without a finalizer, deletion orphans the objects: they keep running with their annotation and no owner. The object annotations `Delete=false` and `Prune=false` protect single objects.

An app-of-apps is a parent Application whose path holds Application manifests and whose destination namespace is the one that holds Applications. Each child syncs its own workloads, and the parent tracks the child objects. A parent without automated sync leaves its children `OutOfSync`, and a finalizer on the parent removes the child Applications, while each child's own finalizer decides what happens to its workloads. Whoever can change the parent's path chooses the project of every child.

Health has the values `Healthy`, `Progressing`, `Degraded`, `Suspended`, `Missing` and `Unknown`, and it is independent of sync status. Built-in checks assess common kinds and Lua checks extend them. An Application takes the worst health of its objects. Health follows the status that Kubernetes publishes, so a failing Deployment stays `Progressing` until its progress deadline passes. The Application kind has no built-in health check, so a parent does not show the health of its children without a custom check.

- The tracking annotation decides which objects an Application owns.
- The finalizer decides whether deletion cascades.
- Sync status and health answer different questions.

<!-- astrona:playground:destroy -->

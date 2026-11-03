---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Resource Tracking, Finalizers, App Of Apps And Application Health

An Application owns a set of live objects, and four questions follow from that. How does Argo CD know which objects are its own? What happens to those objects when the Application is deleted? How can one Application create and manage others? And how does Argo CD decide that the whole set is healthy? This module answers each question and shows the field or annotation that holds the answer.

## Learning goals

- Explain how the tracking annotation `argocd.argoproj.io/tracking-id` links a live object to an Application.
- Say what happens when two Applications render the same object.
- Add the finalizer `resources-finalizer.argocd.argoproj.io` and predict what deleting an Application does with and without it.
- Build an app-of-apps: a parent Application whose source path holds child Application manifests.
- Read the health status of an object and of an Application and say how Argo CD combines them.
- Explain why the health of a child Application does not appear in its parent by default.

## What to know first

You need to know what an Application is, what a sync is and how automated sync with prune works. The playground has Argo CD and a Git server inside the cluster. The seed repository has the paths `workloads/alpha`, `workloads/beta` and `workloads/gamma`, the path `apps` with the manifests of the child Applications `alpha` and `beta`, and the path `broken/bad-image` with a Deployment whose image does not exist.

## Reading order

The first part covers resource tracking. The second part covers finalizers and deletion. The third part covers the app-of-apps pattern. The fourth part covers health status and how it is combined. The fifth part walks through all of them in the playground and ends with a graded lab. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

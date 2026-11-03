---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Summary

Argo CD is a set of separate workloads in one namespace. The standard installation has six Deployments and one StatefulSet. The API server serves users and automation, authenticates them and starts operations. The repository server clones Git and renders manifests, and it changes nothing in Kubernetes. The application controller, a StatefulSet, compares live state with desired state, writes the Application status and is the only component that changes resources in the destination cluster. Redis caches the live resource tree and rendered manifests and holds nothing that cannot be rebuilt. The ApplicationSet controller generates Applications from generators and a template. The Dex server brokers single sign-on, and the notifications controller sends messages about Application events. The last two are optional for delivery.

Components share state through Application objects in the Kubernetes API, and they reach each other through Services. A refresh is a new comparison. The application controller starts it when a watched resource changes, when the reconciliation interval ends, when a webhook arrives or when a user asks, with the annotation `argocd.argoproj.io/refresh` set to `normal` or `hard`. The controller asks the repository server for manifests, which answers from the cache or from Git, then reads live resources and compares. A hard refresh discards the cache first.

A sync is an operation stored on the Application. The API server or the application controller sets it, the controller applies the resources with hooks and sync waves, and the outcome appears in `status.operationState`.

A bad source path or revision is a repository server problem that surfaces on the Application as sync status `Unknown` and a `ComparisonError` condition. The way to diagnose it is to read the condition, then the repository server log, then the application controller log, correct the source and refresh. A role can be read from a workload: the kind shows how it scales, and the program in the container arguments shows what it does.

<!-- astrona:playground:destroy -->

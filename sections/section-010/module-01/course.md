---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Argo CD Desired State And Reconciliation

Argo CD is a continuous delivery tool for Kubernetes that treats Git as the source of truth. You describe what should run in a Git repository, you tell Argo CD where that description lives and where it should run, and Argo CD keeps the cluster equal to the description. This module explains how that loop works, which part does which step, and how to tell from the status fields whether the loop succeeded.

## Learning Goals

After this module you can:

- Explain desired state, live state and reconciliation, and name the Argo CD component that performs each step.
- Describe what an Application is and which fields tell Argo CD where to read and where to deploy.
- Explain why a Git commit is not yet desired state, and what rendering adds.
- Separate sync status from health status and read the four combinations.
- Describe drift and how manual sync, automated sync, pruning and self-healing resolve it.
- Create an Application with `kubectl`, read its status and watch it revert a manual change.

## Before You Start

You need basic Kubernetes knowledge: a Deployment, a Service, a namespace, and the commands `kubectl get` and `kubectl apply`. You need to know what a Git branch, a tag and a commit are. You do not need to know Argo CD.

The playground is a private `kind` cluster. A `kind` cluster is a Kubernetes cluster that runs inside containers on your machine. Argo CD version 3.5.4 is installed in the `argocd` namespace. A small Git server inside the cluster serves one read-only repository at `http://git-source.argocd.svc:8080/repo.git`. It has a directory `plain` with a Deployment and a Service named `git-probe`. The namespaces `starfleet` and `outpost` exist and are empty of Argo CD applications.

## Reading Order

The first part follows the loop from a commit in Git to a status on the Application: what desired state is, how rendering produces it, how live state is compared, and what sync status and health status each answer. The second part is hands-on. You create an Application, read its two statuses, change the live cluster by hand and watch manual and automated sync handle the drift. The module ends with a summary.

Start the playground now and keep it open while you read:

<!-- astrona:playground -->

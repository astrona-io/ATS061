---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Core Concepts, Application Status And The CLI

Every question about an Argo CD installation ends in the same place: the status of an Application. Is it in sync, does it work, which resource is the problem, did the last sync succeed? This module defines the objects and the status fields precisely and teaches the two ways to read them: `kubectl` and the `argocd` command-line client.

## Learning Goals

After this module you can:

- Define Application and AppProject and say what each one restricts.
- Explain target state and live state, and which component produces each.
- Distinguish sync status from health status and name all their values.
- Explain refresh and hard refresh, and when each one helps.
- Explain how Argo CD tracks which resources belong to an Application.
- Use the `argocd` client in core mode to list, read and diff Applications, and read the operation state.
- Correct an Application that is `OutOfSync` and unhealthy.

## Before You Start

You need to know the Application fields `source` and `destination`, what a sync is, and that the application controller compares and applies while the repository server renders. You need `kubectl` basics.

The playground is a private `kind` cluster with Argo CD 3.5.4 in the `argocd` namespace and a read-only Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The repository has the directories `plain`, `workloads/alpha`, `workloads/beta`, `workloads/gamma` and `broken/bad-image`. The last one holds a Deployment whose image tag does not exist. The `argocd` client is installed on your machine.

## Reading Order

The first part defines the objects and the status vocabulary: Application, AppProject, target and live state, the two statuses and their values, resource tracking and the operation state. The second part uses the command-line client in core mode to read those fields, shows what a refresh and a hard refresh change and repairs an unhealthy Application in the playground. The module ends with a summary.

Start the playground now and keep it open while you read:

<!-- astrona:playground -->

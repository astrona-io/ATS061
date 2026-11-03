---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Application Source, Destination And Project Boundaries

An Argo CD Application is the object that ties a place in Git to a place in a cluster. Two questions decide how safe that tie is: what exactly does the Application read, and what exactly may it change? This module answers both. It shows which field selects the Git content, which fields select the cluster and namespace, and how an AppProject limits all of them.

## Learning goals

- Read the `source`, `destination` and `project` fields of an Application and say which component uses each one.
- Explain how a branch, tag or commit in `targetRevision` becomes the exact commit in `status.sync.revision`.
- Choose between `destination.server` and `destination.name` and explain why `destination.namespace` does not rewrite a namespace written in a manifest.
- Write an AppProject with `sourceRepos`, `destinations` and resource allow and deny lists.
- Diagnose an Application that a project refuses by reading `status.conditions`.
- Say what an AppProject restricts and what it leaves to Kubernetes authorization.

## What to know first

You need to know what Kubernetes objects, namespaces and `kubectl` are. The playground has Argo CD installed in the `argocd` namespace and a Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. The seed repository has the branches `main` and `release` and the paths `plain`, `workloads/alpha`, `workloads/beta` and `workloads/gamma`. No Application and no project besides `default` exists when you start.

## Reading order

The first part explains the three fields of an Application: source, destination and project. The second part explains AppProject restrictions and how Argo CD reports a violation. The third part walks through both in the playground and ends with a graded lab. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

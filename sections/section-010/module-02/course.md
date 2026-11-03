---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Argo CD Architecture And Components

An Argo CD installation is not one program. It is a set of separate workloads in one namespace, and each one has a narrow job. When an Application shows `Unknown`, `OutOfSync` or an error, the first question is which component produced that result. This module teaches the components, the path a refresh and a sync take through them, and how to read each component's role from the cluster itself.

## Learning Goals

After this module you can:

- Name the seven Argo CD components, say what each one does and which Kubernetes workload kind runs it.
- Explain which component renders manifests, which one compares them, which one applies them and which one serves the API.
- Describe the path of a refresh and the path of a sync, including where Redis and the Git repository fit.
- Read a component's role from its Deployment or StatefulSet and from its logs.
- Diagnose an Application whose source path or revision is wrong and repair it.

## Before You Start

You need to know what an Application is and what its source and destination fields mean, the difference between sync status and health status, and the commands `kubectl get`, `kubectl logs` and `kubectl apply`. A Deployment runs stateless pods and a StatefulSet runs pods with stable names.

The playground is a private `kind` cluster with Argo CD 3.5.4 in the `argocd` namespace and a read-only Git server inside the cluster at `http://git-source.argocd.svc:8080/repo.git`. In this environment the Dex server and the notifications controller are scaled to zero replicas, so you can see a component that is installed but not running.

## Reading Order

The first part describes each component: what it does, what it talks to and what kind of workload runs it. The second part follows a refresh and a sync through those components and shows how to read their workloads and logs, then you diagnose and repair a broken Application in the playground. The module ends with a summary.

Start the playground now and keep it open while you read:

<!-- astrona:playground -->

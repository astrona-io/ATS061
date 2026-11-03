---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Bootstrap Clusters With App Of Apps

A real cluster runs many Applications, and someone has to create each of them. If a person applies every Application by hand, the list lives in no place, and a new cluster needs the same steps again. The app-of-apps pattern solves this with one parent Application whose Git path holds the manifests of the child Applications. This module explains how the parent and the children relate, who owns what, and how to find the layer that failed.

## Learning goals

- Describe the app-of-apps pattern and what the parent Application compares and syncs.
- Write a parent Application whose destination is the `argocd` namespace.
- Explain what happens to child Applications and their workloads when a child is edited, deleted or removed from Git.
- Say what the finalizer `resources-finalizer.argocd.argoproj.io` changes on deletion.
- Diagnose a missing, out of sync or unhealthy child by checking the parent first and then the child.

## What to know first

You need to know what an Application, a sync and automated sync with self-heal are. The playground has Argo CD and a Git server inside the cluster. The path `apps` of the branch `main` holds two Application manifests, `alpha.yaml` and `beta.yaml`. Each child Application deploys the path `workloads/alpha` or `workloads/beta`, which holds a Deployment and a Service with one replica in the namespace `starfleet`. Both children have automated sync with prune and self-heal.

## Reading order

The first part explains the pattern, the parent Application and the layers of ownership. The second part uses the playground to edit and delete children, remove the parent and read the status of a broken parent, and it ends with a graded lab. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

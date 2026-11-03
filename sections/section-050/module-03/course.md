---
draft: true
exam_objectives:
- Identify Common Reconciliation Patterns
---
# Generate Applications With ApplicationSet

Writing one Application manifest for each service, environment or cluster does not scale, and an app-of-apps parent still needs one file per child. An ApplicationSet solves this with a template and a generator: the generator produces a list of parameter sets, and the template turns each set into an Application. This module explains the generators, the template syntax and the way the ApplicationSet controller owns and repairs the Applications it creates. It also compares this pattern with app-of-apps.

## Learning goals

- Describe the parts of an ApplicationSet: generators, template and sync policy.
- Write a list generator and a Git files generator and use their parameters in a template.
- Explain how the ApplicationSet controller owns generated Applications through owner references.
- Predict what happens when a generated Application is edited, deleted or loses its source file.
- Choose between app-of-apps and an ApplicationSet for a given case.
- Find the failing layer when a generated Application is missing or unhealthy.

## What to know first

You need to know what an Application is and how automated sync with self-heal works. The playground has Argo CD, which includes the ApplicationSet controller, and a Git server inside the cluster. The seed repository has the files `envs/dev/config.json`, `envs/staging/config.json` and `envs/prod/config.json`. Each file holds an `environment` name and a `replicas` count of 1, 2 and 3. The path `kustomize/base` holds the Deployment and Service `git-probe`, and the paths `workloads/alpha`, `workloads/beta` and `workloads/gamma` hold one small workload each.

## Reading order

The first part covers the ApplicationSet object, the generators, the template and the comparison with app-of-apps, and it uses a list generator in the playground. The second part uses a Git files generator, reads the ownership of the generated Applications and tests what the controller repairs, and it ends with a graded lab. The summary closes the module.

Launch the playground and keep it open while you read:

<!-- astrona:playground -->

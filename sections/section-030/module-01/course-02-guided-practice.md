---
draft: true
exam_objectives:
- Use Argo CD Application
---
# Restrict An Application With An AppProject In The Playground

A project limit is easy to write and easy to get wrong, and the only way to trust it is to watch Argo CD refuse something. This practice creates a project that allows one namespace, creates an Application that asks for another, reads the refusal, then widens the project and watches the Application sync. It also changes the allowed repository to see a source refusal. The playground has Argo CD and the Git server at `http://git-source.argocd.svc:8080/repo.git`, and no Application exists.

## Connect to the playground

Point `kubectl` at the playground cluster and make sure the context is the right one. The context name starts with `kind-astro-` followed by the environment name.

<!-- astrona:playground:renew -->

```sh
export KUBECONFIG="$(astrona kubeconfig ats-061-playground-030-01)"
kubectl config current-context
```

The context must be `kind-astro-ats-061-playground-030-01`. Every command below runs against it.

## Create a project that allows only the namespace outpost

The project `crew` allows the internal repository and the namespace `outpost` of the local cluster. It does not allow `starfleet`. Save this as `appproject-crew.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: crew
  namespace: argocd
spec:
  sourceRepos:
  - http://git-source.argocd.svc:8080/repo.git
  destinations:
  - server: https://kubernetes.default.svc
    namespace: outpost
```

Apply it:

```sh
kubectl apply -f appproject-crew.yaml
```

## Create an Application that the project refuses

The Application `crew-probe` deploys the path `plain` to the namespace `starfleet`, which `crew` does not allow. It has automated sync, so Argo CD would deploy it at once if the project allowed it. Save this as `application-crew-probe.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: crew-probe
  namespace: argocd
spec:
  project: crew
  source:
    repoURL: http://git-source.argocd.svc:8080/repo.git
    targetRevision: main
    path: plain
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated:
      prune: true
```

Apply it:

```sh
kubectl apply -f application-crew-probe.yaml
```

Then check the result. Print the conditions and look for the Deployment:

```sh
kubectl -n argocd get application crew-probe -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
kubectl -n starfleet get deployment git-probe
```

The Application should show a condition of type `InvalidSpecError` whose message says that the destination does not match the allowed destinations of the project `crew`. The Deployment should not exist: `kubectl` answers that it is not found. The project stopped the sync before anything reached the cluster. The conditions can take a few seconds to appear, so run the first command again if the list is empty.

## Allow the destination

Add the namespace `starfleet` to the allowed destinations. A merge patch replaces a whole list, so the patch below holds both entries:

```sh
kubectl -n argocd patch appproject crew --type merge -p '{"spec":{"destinations":[{"server":"https://kubernetes.default.svc","namespace":"outpost"},{"server":"https://kubernetes.default.svc","namespace":"starfleet"}]}}'
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/crew-probe --timeout=120s
```

The wait should end with the Application `Synced`. Read the conditions again: the list should be empty now. The sync created the Deployment and the Service `git-probe` in `starfleet`, which you can confirm with `kubectl -n starfleet get deployment git-probe`.

## Refuse the repository

Replace the allowed repository with a different address. The Application keeps its deployed objects, but Argo CD can no longer render its source:

```sh
kubectl -n argocd patch appproject crew --type merge -p '{"spec":{"sourceRepos":["http://git-source.argocd.svc:8080/other.git"]}}'
kubectl -n argocd get application crew-probe -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
```

After a refresh the Application shows a condition of type `InvalidSpecError` that names the repository as not permitted in the project. Restore the original value with the same patch and the first address. The condition disappears at the next refresh. This shows that the project is checked again on every reconciliation and not only when the Application is created.

## Ideas to try on your own

Set `namespaceResourceBlacklist` on the project to deny the kind `Service` and read what the Application reports for the Service. Change the Application to `project: default` and see that all conditions go away, which shows why the right to edit Applications matters as much as the project. Change `destination.namespace` to `outpost` and check where the objects are created, since the manifests name `starfleet` themselves.

## What you saw

You saw an Application refused for its destination and then for its source, you read the refusal from `status.conditions`, and you saw that the repository, destination and kind checks run against the live project. The project is enforced inside Argo CD, before Kubernetes receives any object.

## Common pitfalls

> [!WARNING]
> A merge patch on a list replaces the whole list, so a patch with one destination removes the others. Conditions appear after the next refresh, so wait a few seconds before you decide that nothing was refused. Run `astrona destroy` only when you finish with the playground, because it removes everything you created.

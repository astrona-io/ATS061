# Curriculum Coverage

Exam: Certified Argo Project Associate (CAPA). Domain: ARGO CD (34%).

The [official objectives](https://training.linuxfoundation.org/certification/certified-argo-project-associate-capa/) were checked on 2026-10-11. Teaching structure is independently authored and does not add official requirements.

| Section | Official objective | Modules |
| --- | --- | --- |
| 010 | Understand Argo CD Fundamentals | 3 |
| 020 | Synchronize Applications Using Argo CD | 3 |
| 030 | Use Argo CD Application | 3 |
| 040 | Configure Argo CD with Helm and Kustomize | 3 |
| 050 | Identify Common Reconciliation Patterns | 3 |

| Section / module | Module | Parts |
| --- | --- | --- |
| 010 / 01 | Argo CD Desired State And Reconciliation | 3 |
| 010 / 02 | Argo CD Architecture And Components | 3 |
| 010 / 03 | Core Concepts, Application Status And The CLI | 3 |
| 020 / 01 | Manual And Automated Sync, Pruning And Self-Healing | 4 |
| 020 / 02 | Sync Phases, Waves, Hooks And Options | 3 |
| 020 / 03 | Sync Retries, Sync Windows, Rollback And History | 5 |
| 030 / 01 | Application Source, Destination And Project Boundaries | 4 |
| 030 / 02 | Directory, Helm And Kustomize Sources | 5 |
| 030 / 03 | Resource Tracking, Finalizers, App Of Apps And Health | 6 |
| 040 / 01 | Helm And Kustomize As Argo CD Rendering Inputs | 4 |
| 040 / 02 | Helm Values, Parameters And Release Settings | 4 |
| 040 / 03 | Kustomize Overrides And Inspecting Rendered Output | 4 |
| 050 / 01 | Drift, Refresh, Ignore Rules And Reconciliation Patterns | 4 |
| 050 / 02 | Bootstrap Clusters With App Of Apps | 3 |
| 050 / 03 | Generate Applications With ApplicationSet | 3 |
|  |  |  |

AUTHORING.yaml records measurable goals and adaptation sources. Every objective retains its section ID. All technical readings remain draft. Question banks are separate from the reading manifest and follow their declared summaries. Private playgrounds and independent labs are included. Live verification is recorded separately.

## Hands-On Coverage

This course has 15 ungraded module playgrounds, 21 independent draft labs (16 module labs and 5 capstones) and 5 section quizzes plus a final domain quiz. Tasks, launch entries and solutions follow their teaching reading. Guided practice precedes the summary. All labs and playgrounds are UNTESTED: they were validated statically and never booted.

| Module | Lab in reading order |
| --- | --- |
| 010/01 | Deliver A Git Sourced Application With Argo CD |
| 010/02 | Repair An Application With A Comparison Error |
| 010/03 | Correct An OutOfSync And Unhealthy Application |
| 010 capstone | Repair, Create And Report On Argo CD Applications |
| 020/01 | Repair Live Drift With Self Healing |
| 020/02 | Sync An Ordered Application With Hooks And Options |
| 020/03 | Freeze Automated Syncs And Roll Back A Release |
| 020 capstone | Run A Controlled Release Of The Fleet |
| 030/01 | Restrict An Application To One Repository, Namespace And Kinds |
| 030/02 | Override A Helm Chart And A Kustomize Overlay And Ignore Replicas |
| 030/03 | Build An App Of Apps And Retire A Scratch Application |
| 030 capstone | Bring The Bridge Systems Under Argo CD Control |
| 040/01 | Render A Helm Chart With A Production Values File |
| 040/01 | Deploy A Kustomize Overlay With Argo CD |
| 040/02 | Layer Helm Values For The Fleet Chart |
| 040/03 | Override Kustomize Overlays From Two Applications |
| 040 capstone | Repair And Extend The Fleet Rendering Setup |
| 050/01 | Scope An Ignore Difference Exception |
| 050/02 | Bootstrap The Fleet With An App Of Apps |
| 050/03 | Generate Environments With An ApplicationSet |
| 050 capstone | Bring The Station Fleet Under Three Reconciliation Patterns |

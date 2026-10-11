---
draft: true
exam_objectives:
- Understand Argo CD Fundamentals
---
# Summary

Argo CD compares rendered desired resources with live cluster state and reconciles them under the Application's policy. Repository access, rendering and destination authority are independent dependencies.

Sync status describes alignment, while health describes observed resource condition. Neither alone proves correct business behavior, and manual changes or rendering nondeterminism can create drift that requires an explicit source-of-truth decision.

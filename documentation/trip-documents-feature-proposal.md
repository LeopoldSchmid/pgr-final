# Trip Attachments Feature Proposal

Status: historical proposal, largely superseded by implementation

This document described an earlier plan for trip attachments.
The core capability now already exists in the application via trip attachments and related comments/votes.

Use this file only as historical context for original intent.
Do not treat it as the current implementation contract.

Current source of truth:
- the codebase
- `documentation/stabilization_plan.md`
- `documentation/status_quo.md`

Original proposal summary:
1. allow users to upload files relevant to a trip
2. store attachments via Active Storage
3. associate attachments with trip and uploader
4. render an attachments section on trip pages
5. support deletion and authorization for trip members

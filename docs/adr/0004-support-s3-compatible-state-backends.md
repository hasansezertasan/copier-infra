# Support S3-compatible state backends through the s3 backend

## Context and Problem Statement

The `s3` backend assumed AWS: it had no endpoint setting and required a DynamoDB lock
table. S3-compatible services such as Cloudflare R2 and MinIO have neither, so an infra
repository whose state lives next to its Cloudflare zone could not be rendered.

## Considered Options

* Add a fourth `state_backend` choice per provider (`r2`, `minio`): rejected, each one
  renders the same Terraform `s3` backend and the list would grow without bound.
* Leave it to a hand edit of `backend.tf` after rendering: rejected, it drifts from the
  Template and breaks `copier update`.

## Decision Outcome

`s3` stays the single choice. An optional `state_endpoint` answer selects an S3-compatible
service. When it is set, `backend.tf` renders `endpoints.s3`, the `skip_*` flags such
services need, `use_path_style` (MinIO defaults to path-style lookup), and `use_lockfile = true` instead of `dynamodb_table`; `state_lock_table`
is then optional. Without an endpoint nothing changes: AWS S3 and its lock table.
`state_endpoint` counts as a state coordinate, because moving between providers moves the
state object, so changing it is a state migration.

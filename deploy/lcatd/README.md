# Deploy: read-only cataloging demo (lcatd on Lambda)

The companion to the static catalog (tasks/009): a public, **read-only** `lcatd`
instance so visitors can explore the *cataloging* side of libcatalog -- the editor,
review queue, copy cataloging, profiles -- not just the finished catalog. Live at
https://try.libcatalog.evefreeman.com.

Nothing a visitor does persists: the backend runs with `LCATD_READ_ONLY=1`, which wraps
the grain store read-only and 403s every editorial/config write, while sign-in, reads,
and dry-run previews still work. See libcatalog `backend/deploy/README.md` and tasks/097.

## Shape (cheapest tier)

One arm64 Lambda (`provided.al2023`) serving the libcatalog backend with the cataloging
SPA embedded and the BIBFRAME grains **bundled in the zip** -- in-memory document store,
so **no DynamoDB and no S3**. Fronted by an API Gateway v2 HTTP API on a custom
subdomain. Scale-to-zero: ~$0 when idle. The grains are the same corpus as the static
catalog (this repo's `build/data/works`, from `npm run data:refresh`, tasks/008).

```
Lambda (bootstrap + grains/ + embedded SPA)  <-  API Gateway v2 HTTP API  <-  try.libcatalog.evefreeman.com
  LCATD_READ_ONLY=1, in-memory store, grains at /var/task/grains
```

## Layout

- `build.sh` -- builds `dist/lcatd-demo.zip`: `npm run build` the SPA (libcatalog
  tasks/098), `go build` the arm64 `bootstrap` from `../libcatalog/backend/cmd/lcatd-lambda`,
  bundle `grains/` from this repo's `build/`. Requires a sibling `../libcatalog` checkout.
- `terraform/` -- Lambda + exec role (logs only) + API Gateway v2 HTTP API + ACM cert +
  Route 53 (custom domain). Reads secrets from a gitignored `terraform.tfvars`.
- `deploy.sh` -- `build.sh`, then generate/reuse a stable signing key, then
  `terraform apply`.

## Deploy

```
AWS_PROFILE=deeplibby-admin deploy/lcatd/deploy.sh              # review plan, approve
AWS_PROFILE=deeplibby-admin deploy/lcatd/deploy.sh -auto-approve
```

First apply provisions 15 resources and validates the ACM cert via DNS; the domain is
live once the cert validates and DNS propagates (a few minutes). Redeploy after a data
refresh or module bump by re-running `deploy.sh` (the zip's `source_code_hash` change
triggers a Lambda code update; the signing key is preserved).

## Configuration (terraform variables)

Non-secret vars have sensible defaults (`variables.tf`): `domain`
(`try.libcatalog.evefreeman.com`), `demo_admin` (`demo@example.org:readonlydemo` -- read-only,
safe to publish), `provider_name` (`hardcover`), `region` (`us-east-1`),
`lambda_memory_mb` (512). Secrets go in the gitignored `terraform.tfvars`, written by
`deploy.sh`:

- `hosted_zone_id` -- Route 53 zone for evefreeman.com.
- `local_signing_key` -- base64 Ed25519 seed; **stable** so demo sessions survive Lambda
  cold starts / concurrent instances. `openssl rand -base64 32`.
- `abuse_secret` -- optional (>=16 bytes); only mounts anon suggest/export (writes still 403).

## Notes / caveats

- **Read-only guarantees.** Writes are rejected twice: the blob store returns
  `ErrReadOnly`, and the HTTP guard 403s mutating methods except allow-listed auth and
  dry-run (`/ops`, `/marc`, `/v1/copycat/search`, `/v1/batch/resolve`). Verified:
  `POST /v1/publish` -> 403 (authed and unauthed).
- **In-memory store + cold starts.** Concurrent Lambda instances have separate in-memory
  stores, so a session's *refresh* can miss across instances; the stable signing key
  keeps the access token valid, so re-login is the worst case. The store resets on cold
  start -- desirable for a demo.
- **No authorities seeded.** `build/data/works` has no `data/authorities/`, so vocabulary
  panels read empty. Seed `data/authorities/` into the grains to enrich the editor.
- **Writable production** (persistent DynamoDB + S3) is out of scope here -- see
  libcatalog tasks/099 and `backend/deploy/terraform` (the writable reference stack).

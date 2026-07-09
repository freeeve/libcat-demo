# 027: Bump libcat to lockstep v0.27.0

libcat cut lockstep v0.27.0. For this site:

- Hugo module: bump `github.com/freeeve/libcat/hugo` v0.26.0 -> v0.27.0
  (and the CI pin in scripts/pin-module.sh). No template/schema changes in
  v0.27.0 itself -- the release carries backend-side work -- so this is a
  routine currency bump; the v0.26.0 brand-mark defaults are unchanged.
- If the `deploy/lcatd` sandbox redeploys, rebuild from backend/v0.27.0 and
  run `lcatd vocab-index --all` against its store once: vocabulary schemes
  then serve from range-fetched sidecar indexes instead of resident maps
  (libcat tasks/167; full-LCSH playground dropped 1,250MB -> 483MB RSS),
  and the admin works view gains the faceted filter rail (libcat
  tasks/168). A read-only sandbox sizes down accordingly.

## Outcome

Superseded the v0.27.0 target: libcat had advanced to lockstep v0.72.0 by
pickup, so the site jumped v0.26.0 -> v0.72.0 directly.

- `HUGO_MODULE_VERSION` repo variable set to v0.72.0; CI deploy green
  (run 29019322172, pinned hugo@v0.72.0).
- Module v0.72.0 targets catalog schema 11; reprojected the existing
  build/catalog.nq with lcat v0.72.0 (installed from the published tag --
  the sibling working tree had concurrent uncommitted work) and refreshed
  assets/catalog.json + facets.json (102 works). Doc mentions of schema v9
  updated to v11.
- The lcatd sandbox note (vocab-index sidecar rebuild) was NOT done here --
  it applies only if deploy/lcatd redeploys.

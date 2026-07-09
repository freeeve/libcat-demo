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

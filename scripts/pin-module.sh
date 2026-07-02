#!/usr/bin/env bash
# pin-module.sh -- swap the local sibling `replace` for a published module version so
# CI (which has no ../libcatalog checkout) resolves the Hugo module from the Go proxy
# (tasks/003 §3). Run in CI before `hugo`; do NOT commit the result to main -- local
# dev keeps the replace.
#
#   scripts/pin-module.sh v0.1.0
#   HUGO_MODULE_VERSION=v0.1.0 scripts/pin-module.sh
#
# Prerequisite: the module must be published -- tag github.com/freeeve/libcatalog/hugo
# in the libcatalog repo (e.g. `git tag hugo/v0.1.0 && git push --tags`) or supply a
# pseudo-version. Until then this fails fast with a clear proxy error.
set -euo pipefail

MOD="github.com/freeeve/libcatalog/hugo"
VERSION="${1:-${HUGO_MODULE_VERSION:-}}"
if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <version|pseudo-version>  (or set HUGO_MODULE_VERSION)" >&2
  exit 2
fi

go mod edit -dropreplace="$MOD"
go get "$MOD@$VERSION"
go mod tidy
echo "pinned $MOD@$VERSION (replace dropped)"

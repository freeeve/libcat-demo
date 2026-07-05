#!/usr/bin/env bash
# gen-lcsh.sh -- (re)generate deploy/lcatd/lcsh.nq, the corpus-sized LCSH authority
# snapshot the cataloging demo bundles so its existing subjects render real headings
# instead of "shNNNN not in local index" (tasks/011). Harvests each LCSH subject the
# projected catalog uses from id.loc.gov via `lcat vocab-subset`. Run it after the
# catalog's subjects change (e.g. new books add new LCSH headings); commit the result.
#
#   deploy/lcatd/gen-lcsh.sh
#
# Requires a sibling ../libcatalog checkout and outbound internet (id.loc.gov).
#
# Scheme note: this demo's catalog subjects are https://id.loc.gov/... URIs (from the
# upstream ingest subject-map), but id.loc.gov's canonical identifier -- and so
# vocab-subset's output -- is http://. The vocab index matches subject URIs exactly, so
# the snapshot is realigned to https to match the catalog. (Upstream gotcha: vocab-subset
# reports "0 terms" for an https catalog because its label-match compares against the
# http canonical -- filed as libcatalog tasks/100.)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
LCAT_DIR="$ROOT/../libcatalog"
CATALOG="$ROOT/assets/catalog.json"
OUT="$HERE/lcsh.nq"
NS="https://id.loc.gov/authorities/subjects/"

if [[ ! -f "$CATALOG" ]]; then
  echo "error: $CATALOG missing -- run 'npm run data:refresh' first" >&2; exit 1
fi

echo "==> harvesting LCSH subjects from id.loc.gov (via lcat vocab-subset)"
( cd "$LCAT_DIR" && go run ./cmd/lcat vocab-subset --catalog "$CATALOG" --out "$OUT" --namespace "$NS" )

echo "==> realigning subject URIs to https to match the catalog"
perl -i -pe 's{<http://id\.loc\.gov/authorities/subjects/}{<https://id.loc.gov/authorities/subjects/}g' "$OUT"

echo "done: $OUT ($(grep -c 'prefLabel' "$OUT") prefLabels, $(wc -l < "$OUT" | tr -d ' ') quads)"

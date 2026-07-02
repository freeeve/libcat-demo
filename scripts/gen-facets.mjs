#!/usr/bin/env node
/**
 * gen-facets.mjs -- regenerate assets/facets.json from assets/catalog.json.
 *
 * The libcatalog Hugo module reads facets.json for its facet sidebar counts
 * (tasks/009); this mirrors the projector's ordering so counts stay correct at real
 * scale. Every dimension is sorted count-descending then value/label-ascending, which
 * is what the module's facets.html slices with `first 20`. Never hand-maintain these
 * counts -- run this after any catalog.json change (Hardcover pipeline tasks/001,
 * subject mapping tasks/004).
 *
 * Usage: node scripts/gen-facets.mjs [catalogPath] [facetsPath]
 */
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const CATALOG = process.argv[2] || resolve(HERE, "../assets/catalog.json");
const FACETS = process.argv[3] || resolve(HERE, "../assets/facets.json");

/**
 * Count-desc, then label-asc comparator over {count, sortKey} rows.
 * @param {{count:number, sortKey:string}} a
 * @param {{count:number, sortKey:string}} b
 */
function byCountThenLabel(a, b) {
  return b.count - a.count || a.sortKey.localeCompare(b.sortKey, "en");
}

/**
 * Tally a plain {value,count} dimension: each Work contributes each distinct value once.
 * @param {object[]} works
 * @param {(w:object)=>string[]} pick returns a Work's values for this dimension
 * @returns {{value:string,count:number}[]}
 */
function plainFacet(works, pick) {
  const counts = new Map();
  for (const w of works) {
    for (const v of new Set((pick(w) || []).filter(Boolean))) {
      counts.set(v, (counts.get(v) || 0) + 1);
    }
  }
  return [...counts.entries()]
    .map(([value, count]) => ({ value, count, sortKey: value }))
    .sort(byCountThenLabel)
    .map(({ value, count }) => ({ value, count }));
}

/**
 * Tally the controlled-subjects dimension, keyed by authority id, carrying localized
 * labels and optional skos:broader parents through to facets.json.
 * @param {object[]} works
 * @returns {{id:string,labels:object,broader?:string[],count:number}[]}
 */
function subjectFacet(works) {
  const byId = new Map();
  for (const w of works) {
    const seen = new Set();
    for (const s of w.subjects || []) {
      if (!s || !s.id || seen.has(s.id)) continue;
      seen.add(s.id);
      const row = byId.get(s.id) || { id: s.id, labels: s.labels || {}, broader: s.broader, count: 0 };
      row.count += 1;
      byId.set(s.id, row);
    }
  }
  return [...byId.values()]
    .map((r) => ({ ...r, sortKey: (r.labels && (r.labels.en || Object.values(r.labels)[0])) || r.id }))
    .sort(byCountThenLabel)
    .map(({ sortKey, broader, ...rest }) => (broader ? { ...rest, broader } : rest));
}

const catalog = JSON.parse(readFileSync(CATALOG, "utf8"));
const works = catalog.works || [];

const facets = {
  version: catalog.version,
  languages: plainFacet(works, (w) => w.languages),
  subjects: subjectFacet(works),
  tags: plainFacet(works, (w) => w.tags),
  formats: plainFacet(works, (w) => w.formats),
  contributors: plainFacet(works, (w) => (w.contributors || []).map((c) => c.name)),
  classifications: plainFacet(works, (w) => w.classifications),
};

writeFileSync(FACETS, JSON.stringify(facets, null, 2) + "\n");
console.log(
  `facets.json: ${works.length} works -> ` +
    Object.entries(facets)
      .filter(([k]) => k !== "version")
      .map(([k, v]) => `${v.length} ${k}`)
      .join(", ")
);

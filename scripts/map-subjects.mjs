#!/usr/bin/env node
/**
 * map-subjects.mjs -- promote free genre tags into controlled subjects (tasks/004).
 *
 * libcatalog draws a first-class line between controlled subjects (authority URIs with
 * localized labels + optional skos:broader) and uncontrolled tags (free genre strings).
 * Hardcover delivers genres as free tags (tasks/001); this step, driven entirely by
 * data/subject-map.json (not hardcoded per Work), moves each mappable tag into the
 * Work's subjects[] with its authority metadata and leaves the rest in tags[] so both
 * dimensions coexist. Every subject's {labels, broader} is sourced from the map's
 * `authorities` table, so labels stay consistent across Works and the demo can show
 * localized labels + vocabulary hierarchy.
 *
 * Idempotent: re-running maps the same tags to the same subjects and re-normalizes
 * existing subjects' metadata from the authorities table. Run gen-facets.mjs after.
 *
 * Usage: node scripts/map-subjects.mjs [catalogPath] [mapPath]
 */
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const CATALOG = process.argv[2] || resolve(HERE, "../assets/catalog.json");
const MAP = process.argv[3] || resolve(HERE, "../data/subject-map.json");

/**
 * Build a controlled-subject object for an authority id, preferring the map's
 * authorities table and falling back to any labels already on the Work's subject.
 * @param {string} id authority URI
 * @param {object} authorities id -> {labels, broader}
 * @param {object} [fallback] the Work's existing subject object for this id
 */
function subjectFor(id, authorities, fallback) {
  const meta = authorities[id] || {};
  const labels = meta.labels || (fallback && fallback.labels) || {};
  const out = { id, labels };
  if (meta.broader && meta.broader.length) out.broader = meta.broader;
  else if (fallback && fallback.broader) out.broader = fallback.broader;
  return out;
}

const catalog = JSON.parse(readFileSync(CATALOG, "utf8"));
const map = JSON.parse(readFileSync(MAP, "utf8"));
const genreToSubject = map.genreToSubject || {};
const authorities = map.authorities || {};

let promoted = 0;
let worksTouched = 0;

for (const work of catalog.works || []) {
  const existing = new Map((work.subjects || []).map((s) => [s.id, s]));
  const orderedIds = [...existing.keys()];
  const keptTags = [];
  let touched = false;

  for (const tag of work.tags || []) {
    const id = genreToSubject[String(tag).toLowerCase().trim()];
    if (id) {
      if (!existing.has(id)) {
        existing.set(id, null);
        orderedIds.push(id);
      }
      promoted += 1;
      touched = true;
    } else {
      keptTags.push(tag);
    }
  }

  work.subjects = orderedIds.map((id) => subjectFor(id, authorities, existing.get(id)));
  if (keptTags.length) work.tags = keptTags;
  else delete work.tags;
  if (touched) worksTouched += 1;
}

writeFileSync(CATALOG, JSON.stringify(catalog, null, 2) + "\n");
console.log(`map-subjects: promoted ${promoted} tag(s) to controlled subjects across ${worksTouched} work(s).`);

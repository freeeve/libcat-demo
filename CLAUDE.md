# libcatalog-demo (Eve's Library)

Public demo site for the [libcatalog](https://github.com/freeeve/libcatalog) Hugo module,
deployed at https://libcatalog.evefreeman.com. It is a reference **adopter**: a plain Hugo
site that imports the module and provides projected data under `assets/`.

## Layout

- `hugo.toml` -- imports the module, declares taxonomies, enables Pagefind search.
- `go.mod` -- `replace`s the module to `../libcatalog/hugo` for local dev; CI pins a
  published version.
- `assets/catalog.json` / `assets/facets.json` -- projected data (schema version 5).
  Currently placeholder public-domain classics; the Hardcover pipeline (`tasks/001`)
  replaces them. Keep `facets.json` consistent with `catalog.json` (regenerate, do not
  hand-edit counts once the pipeline lands).

## Build

`npm run build:full` = `hugo --minify` then `npm run search:index` (Pagefind over
`public/`). Requires a sibling `../libcatalog` checkout for the module `replace`.

## Conventions

Task files live in `tasks/` (numbered `NNN_description.md`); status via rename
(`.in-progress.md` / `.done.md`). Do not commit `public/` (gitignored). This repo does not
contain the module -- template/asset changes belong in the libcatalog repo, not here.

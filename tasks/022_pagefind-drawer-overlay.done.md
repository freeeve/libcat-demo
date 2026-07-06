# 022 -- Fix: search results blow up the page (Pagefind drawer in header flow)

User-reported: running a search reflowed the whole page -- header squeezed into a
left column, search results occupying the right half of the viewport.

**Base-theme bug, not ours** (this repo shadows nothing and its chrome never
touched search): the module's search-pagefind.html mounts the entire Pagefind
Component UI -- input, filter accordions, results -- in normal flow inside the
.lcat-header flex row, with no positioning on the drawer. Any search with results
inflates the header and reflows the page, on every adopter site.

Stopgap here (adopter CSS in lcat-theme.css, no shadow): position
`.pagefind-ui__drawer:not(.pagefind-ui__hidden)` as an absolute overlay dropdown
anchored under the search box (themed surface/border/shadow, max-height +
overflow, z-index), plus map the unset `--pagefind-ui-tag` chip background to
--lcat-surface-alt (was unreadable in dark mode). Filed upstream as libcatalog
tasks/127 with both fixes; these rules drop when the module ships them.

Verified with CDP-driven headless Chrome (type into the Pagefind input, wait,
screenshot -- scratchpad cdp-search.mjs pattern): light + dark both show a proper
dropdown card, header intact, one correct highlighted result, readable chips.

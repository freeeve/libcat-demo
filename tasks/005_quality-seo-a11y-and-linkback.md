# 005 -- Quality pass: SEO, a11y, and link-back

## Context

Final polish so the demo is a credible showcase and discoverable, and so the libcatalog
project points at it.

## Scope

1. **Accessibility.** Run the module's axe audit (WCAG 2.1 A/AA) against this site's
   `public/`, and manually check color-contrast in a real browser (jsdom can't). Verify
   the Pagefind widget is keyboard- and screen-reader-navigable. Fix any regressions from
   the branding overrides (`tasks/002`).
2. **SEO / social.** Per-page `<title>`/`<meta description>`, Open Graph + Twitter card
   tags (title, description, cover image where available), a `sitemap.xml` (Hugo emits
   one), `robots.txt`, and a canonical URL. Add a favicon / touch icons and a web
   manifest.
3. **Structured data (optional).** Emit schema.org `Book` / `CreativeWork` JSON-LD on
   Work pages (libcodex can produce schema.org; or template it) to demonstrate rich
   bibliographic markup.
4. **Performance.** Confirm CloudFront compression + cache headers (`tasks/003`), lazy-
   load cover images, and check a Lighthouse pass (performance + a11y + SEO).
5. **Link-back.** Once live, add the demo URL to the libcatalog repos:
   - top-level `README.md` and `hugo/README.md` (a "Live demo" line).
   - NOTE: that change lands in the **libcatalog** repo, not here. Per the workspace
     convention, make it there (or leave a task file there); do not edit that repo from
     this one.

## Acceptance

- Clean axe audit + verified contrast; Pagefind search fully keyboard/AT accessible.
- Valid OG/Twitter/sitemap/robots/favicon; good Lighthouse scores.
- libcatalog READMEs link to https://libcatalog.evefreeman.com.

## Refs

- libcatalog `tasks/014` (a11y audit tooling), `tasks/017` (Pagefind). Hugo SEO
  internals (`_internal/opengraph`, `schema`, `twitter_cards`).

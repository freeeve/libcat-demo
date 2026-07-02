---
title: "Theming it, with examples"
summary: "Re-color the whole site by setting a few CSS variables; go further with an override stylesheet and template shadows."
weight: 30
---

The libcatalog module ships a minimal, accessible reference theme driven by CSS custom
properties. An adopter re-themes by **layering on top** — no forking.

## 1. Recolor with tokens

The module's components read `--lcat-*` variables. Set them in your own stylesheet and
every component re-themes at once. This site's entire palette is just:

```css
:root {
  --lcat-fg: #1c1b18;      /* ink */
  --lcat-bg: #fbf9f4;      /* warm paper */
  --lcat-accent: #115c52;  /* deep teal (WCAG-AA on the bg) */
  --lcat-muted: #5c574e;
  --lcat-border: #e2dccd;
  --lcat-maxw: 72rem;
}
```

Load your stylesheet after the module's. Because Hugo lets a site override any module
asset, you can add a `<link>` in a `baseof.html` override, or shadow the module's
`assets/lcat.css` outright. This demo adds `assets/lcat-theme.css` and links it after
`lcat.css`.

> **Tip:** keep contrast at WCAG AA. This site computes the ratio for every color pair;
> the lowest is 5.6:1.

## 2. Add components

Beyond colors, you can add your own CSS classes for things the module doesn't ship — the
homepage hero, the events cards, the cover thumbnails here are all plain `evl-*` classes
in `assets/lcat-theme.css`.

## 3. Shadow a template (only when you must)

Any file in the module's `layouts/` can be replaced by putting a file at the same path in
your site. This demo shadows a few — e.g. `layouts/_partials/work-card.html` to add a
cover image:

```html
<article class="lcat-card evl-card">
  {{ partial "cover.html" (dict "page" . "class" "evl-cover") }}
  <div class="evl-card-body">
    <h2 class="lcat-card-title"><a href="{{ .RelPermalink }}">{{ .Title }}</a></h2>
    ...
  </div>
</article>
```

Shadowing copies module logic, so do it sparingly — prefer tokens and added CSS. (This
demo files upstream requests so the shadows it *did* need can eventually be dropped.)

## 4. Add whole pages and sections

The homepage, [events](/events/), and these docs aren't part of the module at all — they
are ordinary Hugo content + layouts in this repo. Mixing your own sections with the
catalog is exactly the point.

Next: [what it costs to run, and who can edit it](/docs/running-it/).

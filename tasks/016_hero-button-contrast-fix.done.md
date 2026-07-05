# 016 -- Fix: hero "Browse the catalog" button unreadable (white-on-white in light mode)

Reported after the hugo/v0.4.2 pin went live: light theme showed white button text
on the button's white surface in the homepage hero.

Cause: demo CSS, not the module. `.evl-hero a` (specificity 0-1-1) forced
`color: var(--lcat-on-accent)` onto every hero link, beating the button variants'
own color rules (0-1-0). For `.evl-btn--light` (background: --lcat-surface) that
meant on-accent-on-surface: #fff on #fff in light mode, #10261c on #212724 in dark
-- unreadable both ways. Present locally too (module CSS identical hugo/v0.4.2 ==
sibling head); it only *looked* new because the deployed site was previously pinned
to hugo/v0.1.0.

Fix: `.evl-hero a:not(.evl-btn)` so each `.evl-btn` variant owns its color pair.
Verified with headless-Chrome screenshots of the built site in forced-light
(data-lcat-theme=light) and dark: both buttons legible, hero links still on-accent.

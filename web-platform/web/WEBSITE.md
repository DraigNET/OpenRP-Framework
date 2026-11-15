# Public website template

The bundled Next.js application serves the public website, UCP and ACP together.
The separate root `Website/` directory is the framework's project landing page.

Edit `lib/site-config.ts` to set the community name, introductory text, public
HTTPS origin, multiplayer address and optional Discord, forum and support links.
Leave optional links empty to hide them. No server-online claim is hardcoded.

The default artwork is `public/img/san-andreas-dashboard.png`. The shared logo is
`public/favicon.png`; faction badges are `public/img/departments/1.png` and `2.png`.
The public website theme is scoped in `app/(site)/site.css`.

Player guide text lives in `lib/data/site-guides.ts`. Review it against the features
you enable. Add community rules, terms and privacy information to the corresponding
arrays in `site-config.ts` before opening registration to players. Empty arrays
show an explicit unpublished state. No previous community's policies are supplied.

Add dated announcements to `siteConfig.updates`, newest first. These populate
`/changelog` and `/changelog/feed.xml`. The initial list is empty. Donations have
no default prices or benefits; `/donators` only links to a configured support URL.

Framework contributor credits are available at `/credits`.

Discord sign-in and account linking are disabled by default. To opt in, set
`DISCORD_ENABLED=true` and configure all Discord OAuth, bot, guild and role
variables listed in `.env.example`. Both initiation and callback routes reject
requests while disabled; username/password login remains available.

# fuori-webapp

The [Fuori Limited](https://www.fuori.co.uk/) website: a single static page served by Firebase Hosting (project `fuoriapp`).

## Layout

| Path                    | What                                                                                                                      |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `public/`               | Everything that gets deployed: `index.html`, `404.html`, `styles.css`, favicon, social image, `robots.txt`, `sitemap.xml` |
| `assets/og-image.svg`   | Source for `public/og-image.png` (the social preview image)                                                               |
| `firebase.json`         | Hosting config: security and cache headers, emulator port                                                                 |
| `scripts/smoke-test.sh` | Checks status codes and headers against a URL                                                                             |
| `lighthouserc.json`     | Lighthouse CI score thresholds                                                                                            |

There is no build step. Files in `public/` are served as-is.

## Prerequisites

- Node.js, version in `.nvmrc` (`nvm use`)
- [Firebase CLI](https://firebase.google.com/docs/cli) for `npm start` (`brew install firebase-cli`)
- `rsvg-convert` for `npm run og-image` (`brew install librsvg`)

Then `npm ci`.

## Scripts

| Command            | What it does                                                                                                                            |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| `npm start`        | Serves the site with the Firebase Hosting emulator at http://localhost:5050, applying the headers and 404 handling from `firebase.json` |
| `npm run smoke`    | Runs the smoke test against the emulator (start it first)                                                                               |
| `npm run lint`     | Biome check with fixes. `npm run lint:ci` checks without fixing                                                                         |
| `npm run og-image` | Regenerates `public/og-image.png` from `assets/og-image.svg`                                                                            |

## CI/CD

| Workflow                               | When                          | What                                                                                                       |
| -------------------------------------- | ----------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `PR checks` (`fuori-review.yml`)       | Every PR                      | Biome lint. For branches in this repo: deploys a Firebase preview channel, then runs Lighthouse against it |
| `PR lint` (`pr-lint.yml`)              | PR opened, edited or reopened | Checks the PR title follows [Conventional Commits](https://www.conventionalcommits.org/)                   |
| `Fuori main` (`fuori-main.yml`)        | Push to `main`                | Deploys live, then smoke tests `https://fuoriapp.web.app`                                                  |
| `Daily site check` (`fuori-daily.yml`) | 06:17 UTC daily, or manually  | Smoke tests `https://www.fuori.co.uk` to catch domain, DNS and certificate problems                        |

Lighthouse fails the PR if performance, best practices or SEO score below 0.9, or accessibility below 0.95. The `is-crawlable` and
`canonical` audits are skipped because preview channels are `noindex` and the canonical URL points at `www.fuori.co.uk`.

PRs are squash-merged, so the PR title becomes the commit message on `main`. Renovate keeps dependencies and pinned actions up to date.

## Things to know before changing the page

- **Content Security Policy.** `firebase.json` sends `default-src 'self'`, so the page can only load files from its own origin. External
  fonts, analytics, CDNs and inline `<script>`/`style=""` will be blocked until the policy is updated. The JSON-LD block in
  `index.html` is fine because it is data, not executed script.
- **Smoke test.** `scripts/smoke-test.sh` checks for specific headers and paths. If you change headers in `firebase.json` or rename files
  in `public/`, update the script to match, or the deploy check will fail.
- **Caching.** CSS is cached for an hour, SVG and PNG for a day, and file names aren't fingerprinted, so visitors may see an old version
  for up to that long after a deploy.
- **Canonical URL.** `index.html`, `sitemap.xml`, `robots.txt` and the social image all use `https://www.fuori.co.uk/`.
- **Colours.** The accent colour is charcoal `#263238` (`#b0bec5` in dark mode), set as CSS custom properties in `styles.css`. All text
  colours pass WCAG AA in light and dark mode. Check contrast if you change them.

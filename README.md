# 🚀 Path Aviator

[![CI](https://github.com/MeghaKoshti/path-aviator/actions/workflows/ci.yml/badge.svg)](https://github.com/MeghaKoshti/path-aviator/actions/workflows/ci.yml)

**Path Aviator is an AI-powered learning planner built with Ruby on Rails 8.** Paste a job post (or name a skill), your current level and the hours you have each week. It plans a week-by-week route of courses, docs, videos, articles and practice with checked links, tracks your progress as you tick steps off, and gives you a public progress page and a certificate for your CV.

It is a freemium product: **Free** plans 3 paths a month; **Pro** is ₹199/month or ₹1,499/year in India and $6/month or $48/year elsewhere, sold through a swappable billing provider (Dodo Payments, Razorpay, or a fake provider for development).

![A Path Aviator learning path for Ruby on Rails, three of eight steps done, with private notes, progress, time left and a share link](docs/screenshots/path.jpg)

## Status

| Area | Status |
|---|---|
| Rails 8 app setup (Solid Queue, Solid Cache, Solid Cable, Kamal) | ✅ Done |
| Authentication (Rails 8 built-in: sessions, password reset) | ✅ Done |
| Design system, landing page and app shell (Tailwind CSS) | ✅ Done |
| Sign-up, with first-time users sent to onboarding | ✅ Done |
| Three-step onboarding (topic, level, weekly hours and goal) | ✅ Done |
| AI path generation (Gemini, background job, live Turbo Stream updates) | ✅ Done |
| Progress tracking: tick steps, % complete, time left, "Continue" | ✅ Done |
| Dashboard of all your paths | ✅ Done |
| Weekly stats: time against your goal, days learned, streak | ✅ Done |
| Path management: try again, regenerate, delete | ✅ Done |
| Account settings: profile, password, delete account | ✅ Done |
| Private notes on each step, edited in place | ✅ Done |
| Public read-only share links for a path (turn off any time) | ✅ Done |
| Accessibility (WCAG 2.1 AA checks, keyboard) and responsive pass | ✅ Done |
| Checked resource links: SSRF-safe checker, badges, a substitute for broken links, weekly recheck (Pro) | ✅ Done |
| Path from a job post or a finish date: skills it covers, steps sized to the date, on track / behind | ✅ Done |
| Per-user time zone (detected at sign-up, editable) and a Sunday check-in email with one-click unsubscribe | ✅ Done |
| Ops: `/admin` for ADMIN_EMAILS, error reporting, first-party activation events, "Download my data", nightly backups | ✅ Done |
| CI: tests, system tests, RuboCop, Brakeman, importmap audit | ✅ Done |
| Privacy, terms, refund and contact pages, sign-up consent | ✅ Done (needs owner review) |
| Pricing page (INR/USD, monthly/yearly toggle, FAQ) and job-switch landing copy | ✅ Done |
| Plans and quotas: Free 3 paths a month, Pro 30 (fair use), a global daily AI cap, Gemini thinking budget and token logging | ✅ Done |
| Email verification before a second path, with rate-limited resend | ✅ Done |
| Billing: `Billing::Provider` with Dodo Payments, Razorpay and a fake provider; signed, idempotent webhooks; Plan & billing in settings | ✅ Done (needs a payment account) |
| Shareable proof: link previews, "Copy this path", Pro completion certificate with LinkedIn "Add to profile" | ✅ Done |
| SEO: 10 curated `/learn` study plans, sitemap.xml, robots.txt, JSON-LD, canonical links | ✅ Done |
| Google / GitHub sign-in | 📝 Planned |

## Screenshots

<table>
  <tr>
    <td width="50%"><b>Landing</b><br><img src="docs/screenshots/landing.jpg" alt="Landing page: hero with a sample route and the three how-it-works steps"></td>
    <td width="50%"><b>Dashboard</b><br><img src="docs/screenshots/dashboard.jpg" alt="Dashboard: this week's time against a 6 hour goal, the days learned, a 3-day streak, and two path cards"></td>
  </tr>
  <tr>
    <td><b>Learning path</b><br><img src="docs/screenshots/path.jpg" alt="Learning path with ticked steps, private notes, a Link checked badge on every step, progress and the share panel"></td>
    <td><b>Shared path</b><br><img src="docs/screenshots/share.jpg" alt="Public read-only page of a shared path: title, summary, progress and steps, with no notes or email"></td>
  </tr>
  <tr>
    <td><b>Step notes</b><br><img src="docs/screenshots/notes.jpg" alt="A saved note on a finished step and the note editor open on the next step"></td>
    <td><b>Onboarding</b><br><img src="docs/screenshots/onboarding.jpg" alt="Onboarding step two of three: choosing the starting level"></td>
  </tr>
  <tr>
    <td><b>Generating</b><br><img src="docs/screenshots/generating.jpg" alt="Planning state while the AI builds the path"></td>
    <td><b>Settings</b><br><img src="docs/screenshots/settings.jpg" alt="Account settings: profile and password"></td>
  </tr>
  <tr>
    <td><b>Sign up</b><br><img src="docs/screenshots/sign-up.jpg" alt="Sign-up form"></td>
    <td><b>Sign in</b><br><img src="docs/screenshots/sign-in.jpg" alt="Sign-in form"></td>
  </tr>
  <tr>
    <td><b>Pricing</b><br><img src="docs/screenshots/pricing.jpg" alt="Pricing page: Free at ₹0 and Pro at ₹199 a month, with monthly/yearly and INR/USD toggles"></td>
    <td><b>Plan from a job post</b><br><img src="docs/screenshots/onboarding-job-post.jpg" alt="New path from a job post: job title and the pasted post, with a note that emails and phone numbers are removed"></td>
  </tr>
  <tr>
    <td><b>Certificate</b><br><img src="docs/screenshots/certificate.jpg" alt="Public completion certificate for Git and GitHub essentials with the steps, study time, dates, evidence links and an Add to LinkedIn button"></td>
    <td><b>Study plan (/learn)</b><br><img src="docs/screenshots/learn.jpg" alt="Public Ruby on Rails developer roadmap 2026 study plan, week by week, with a Make this plan mine button"></td>
  </tr>
  <tr>
    <td><b>Admin</b><br><img src="docs/screenshots/admin.jpg" alt="Admin dashboard: users, verified and Pro users, generations, AI cost, paths by status and the activation funnel"></td>
    <td></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><b>Mobile</b><br><img src="docs/screenshots/mobile.jpg" alt="Learning path on a 375 pixel wide phone screen" width="300"></td>
  </tr>
</table>

## Tech stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails 8.1 |
| Auth | Rails 8 authentication generator (`has_secure_password`, sessions) |
| Frontend | Hotwire (Turbo Frames, Turbo Streams, Stimulus) with Importmap |
| Styling | Tailwind CSS (`tailwindcss-rails`) |
| AI | Google Gemini API (JSON mode), validated before saving |
| Database | SQLite |
| Background jobs | Solid Queue |
| Real-time updates | Action Cable with Solid Cable |
| Caching | Solid Cache |
| Assets | Propshaft + Thruster |
| Deployment | Kamal (Docker) |

## How it works

```mermaid
flowchart LR
  A[Onboarding form<br/>topic, level, hours] -->|creates goal + path<br/>status: generating| B[(SQLite)]
  A -->|enqueues| C[GenerateLearningPathJob<br/>Solid Queue]
  C -->|prompt| D[Gemini API]
  D -->|JSON| E[PathGenerator::Validator<br/>6–12 steps, http links, minutes]
  E -->|valid: save steps, status ready<br/>invalid twice: status failed| B
  C -->|broadcast_refresh| F[Turbo Stream<br/>over Action Cable]
  F -->|replaces the path page<br/>and dashboard card| G[Browser]
```

1. Onboarding saves a learning goal and a path in the `generating` state, queues `GenerateLearningPathJob` and opens the path page. That page subscribes to the user's Turbo Stream.
2. The job asks Gemini for a strict JSON plan. `PathGenerator::Validator` checks it: 6 to 12 steps, required fields, a known resource type, http(s) links and positive minutes. A bad answer gets one retry. After that the path is marked `failed` with a friendly message and a "Try again" button.
3. When the job finishes, it broadcasts the re-rendered path partial. The page swaps from the planning animation to the route without a reload, and a polite live region tells screen reader users.
4. Ticking a step sends a `PATCH` and gets back Turbo Streams that update the route, the progress panel and the time left. Counter caches keep the dashboard to a fixed number of queries.
5. Each step has a private note, edited in place inside a Turbo Frame (Esc cancels). The dashboard's "This week" panel works out time against the weekly goal and the streak from when steps were ticked.
6. Sharing gives a path a random token and a public, `noindex` page at `/p/:token` with the steps and progress only. "New link" swaps the token and "Stop sharing" clears it, so old links 404. Visitors can "Copy this path": they get the same steps with fresh progress, and no AI call is made (guests sign up first and the copy is made straight after).
7. When every step is ticked, Pro users can publish a certificate at `/c/:token` with optional evidence links per step and a LinkedIn "Add to profile" link. It goes offline if a step is un-ticked, and the owner can revoke it. Every page carries Open Graph and Twitter tags with one static 1200×630 card (`app/assets/images/og-card.svg`, rendered to PNG).
8. `/learn/:slug` serves ten curated, link-checked study plans from `config/learn_topics.yml` (long-tail searches such as "system design in 8 weeks" or "DSA in 12 weeks while working"), with `Course`/`ItemList` JSON-LD and a "Make this plan mine" button that copies the plan without an AI call. `/sitemap.xml` lists them with the landing, pricing and policy pages; `/robots.txt` points to it and keeps crawlers out of the signed-in app. To add a plan, add an entry to the YAML, open every link once and update `checked_on`.

Without a `GEMINI_API_KEY` (and always in tests), a built-in fake generator returns a realistic sample path, so the whole flow works offline.

## Getting started

### Prerequisites

- Ruby 3.3 (see `.ruby-version`)
- No Node.js needed (Importmap + `tailwindcss-rails`)

### Setup

```bash
git clone git@github.com:MeghaKoshti/path-aviator.git
cd path-aviator

bin/setup --skip-server   # bundle install + db:prepare
bin/rails db:seed         # demo account with two sample paths

bin/dev                   # Rails server + Tailwind watcher
```

Open http://localhost:3000 and sign in with the demo account:

| Email | Password |
|---|---|
| `demo@pathaviator.dev` | `pathaviator-demo` |

The demo account is shared, so its settings (name, email, password, time zone, data export) are locked, it can't be deleted, it can't buy Pro, and password reset emails are never sent for it. It counts as email-confirmed and has no monthly quota (the global daily AI cap still applies). Everything else (planning paths, notes, ticking steps, sharing) works as for any account.

To try Pro locally, sign up for your own account (the confirmation link is printed in `log/development.log`, see [Email](#email)), click **Upgrade** on `/pricing` and pay on the fake checkout.

### Background jobs

- **Development:** jobs run inside the Rails server (Active Job `:async` adapter), so `bin/dev` is all you need. Live updates use the in-process Action Cable adapter.
- **Production:** jobs run on Solid Queue. `config/deploy.yml` sets `SOLID_QUEUE_IN_PUMA=true` so one container serves web and jobs. To run a separate worker, use `bin/jobs`.

### AI generation (optional)

| Variable | Purpose |
|---|---|
| `GEMINI_API_KEY` | Enables real path generation with Google Gemini. Leave it unset to use the built-in sample generator. |
| `GEMINI_MODEL` | Model name, defaults to `gemini-2.5-flash`. |
| `GEMINI_THINKING_BUDGET` | Cap on Gemini's thinking tokens (billed as output). Defaults to `1024`; `0` turns thinking off, empty or `-1` lets the model decide. |

```bash
GEMINI_API_KEY=your-key bin/dev
```

### Ops

- **`/admin`** (only for `ADMIN_EMAILS`, a 404 for everyone else): users, verified and Pro users, paths by status, generations today and this month, an estimated AI cost, the activation funnel and the last 50 failed generations.
- **Errors:** a `Rails.error` subscriber sends every reported or unhandled error to `ErrorReporter`. The log adapter is the default; a Sentry or AppSignal adapter is one more class behind `ERROR_REPORTER`.
- **Analytics:** an `events` table records `signed_up`, `path_ready`, `path_failed`, `first_step_done`, `returned_week_2` and `upgraded`. First-party only, no scripts; a deleted account's events stay without the user.
- **Download my data:** Settings builds a `.tar.gz` in a background job with `data.json` (account, goals including job posts, paths, steps, notes, events) and a Markdown checklist per path.
- **Backups:** see `BACKUP_DIR` under Deploy.

### Time zones and the weekly email

Sign-up stores the browser's time zone (a Stimulus controller fills a hidden field) and Settings can change it. Every request runs in the user's zone (`Time.use_zone`), so the week, "today" and streaks follow their local midnight. `WeeklyDigestJob` runs hourly and sends `WeeklyDigestMailer` to each opted-in user at 6pm on their own Sunday, if they learned something in the last 30 days, never to the demo account. Each email has a signed one-click unsubscribe link plus `List-Unsubscribe` headers. Preview it at `/rails/mailers/weekly_digest_mailer/check_in`.

### Paths from a job post

"I have a job post" on the new-path page takes a job title, the pasted post (up to 6,000 characters) and an optional finish date. Email addresses and phone numbers are removed (`PiiScrubber`) before the post is saved, so they never reach Gemini, and the post itself is never shown on a shared page. The prompt fences the post off as data, asks for the 3-8 skills it requires, compares them with the learner's level and fits the steps into the weeks left at their weekly hours; `PathGenerator::Validator` checks the skills list and the time budget (25% slack). The path shows "Skills this covers", the finish date and whether the learner is on track, and so does the dashboard's "This week" panel. Everyone gets one job-post path free; more are Pro.

### Link checks

After a path is generated, `CheckLinksJob` opens every step's link with `LinkChecker` and the page shows "Link checked {date}", "Couldn't verify link" or "Link may be broken. Search instead". A broken link gets one substitute from the generator (`PathGenerator.replace_step`); if that is broken too, the step keeps its link and offers a search. Pro users' active paths are checked again every Monday (`RecheckLinksJob`).

| Answer | Counts as | Why |
|---|---|---|
| 2xx (after at most 3 redirects) | ok | The page opens |
| 401, 403, 429, 999, 5xx, timeout, reset connection | unverified | Big sites (LinkedIn, Medium, Udemy, Cloudflare-fronted docs) turn bots away or hiccup; the page usually works in a browser, so it is never replaced |
| 404, 410, other 4xx, unknown host, refused connection, TLS error, redirect loop, more than 3 redirects | broken | The link really doesn't work |
| Not http(s), a port other than 80/443, or any hop that resolves to a private, loopback, link-local or metadata address | broken | Blocked before connecting, so a generated link can never reach the server's own network (SSRF) |

Every hop is resolved and checked, then the request goes to that vetted IP (no proxy), with HEAD first and GET as a fallback, a 5-second timeout, at most 16 KB of body read and a `PathAviatorLinkChecker/1.0` user agent. Tests never use the network (`LinkChecker::Fake`).

### Plans and quotas

| | Free | Pro |
|---|---|---|
| New paths and regenerations | 3 a month | 30 a month (fair use, shown as "unlimited") |
| Progress, notes, weekly stats, streak, link check when planned, data export | ✅ | ✅ |
| Public share page | With a "Made with Path Aviator" line | Without branding |
| Plan from a job post | The first one | ✅ |
| Weekly link re-check with replacements | | ✅ |
| Completion certificate with LinkedIn "Add to profile" | | ✅ |
| Price | ₹0 | ₹199/month or ₹1,499/year (incl. GST); $6/month or $48/year |

Plans, prices and limits live in `config/plans.yml` (read through `Plan`); the pricing page, checkout and quota checks all read it. Every AI call is recorded in the `generations` table. A new path or a regeneration (including job-post paths) is checked before a job is queued; copying a shared path or a /learn plan makes no AI call and costs nothing. A broken link's substitute (`CheckLinksJob`) counts only towards the daily cap:

- **Free:** 3 generations per calendar month (UTC, whatever the user's own time zone). **Pro:** 30 (fair use). A generation that fails on our side doesn't count.
- **Global daily cap:** once `AI_DAILY_GENERATION_LIMIT` generations (default `500`) have run today, new ones are refused with a "busy, try later" message and a `[AI cost guard]` log line. This also covers the demo account, which has no monthly quota.
- **Rate limit:** 5 new paths and 5 regenerations per user per 10 minutes.
- Gemini's token usage (`usageMetadata`) is saved on each path (`input_tokens`, `output_tokens`, `thinking_tokens`).

| Variable | Purpose |
|---|---|
| `AI_DAILY_GENERATION_LIMIT` | Most generations the whole app runs in one UTC day. Default `500`. |
| `GEMINI_THINKING_BUDGET` | Cap on Gemini's thinking tokens per request (see [AI generation](#ai-generation-optional)). |
| `AI_USD_PER_MILLION_TOKENS` | Price used for the admin page's cost estimate. Default `1.5`. |

### Email

Sign-up sends a link to confirm the address (a signed token from `generates_token_for`, valid for 3 days and void once the email changes). Until it's confirmed, an account can plan **one** path; the dashboard, settings and new-path page offer a rate-limited "Resend the link". Changing the email in settings asks for the new address to be confirmed. The shared demo account counts as confirmed.

Emails use one branded layout (`app/views/layouts/mailer.*`) with HTML and text parts. Preview them at `/rails/mailers` in development (`test/mailers/previews`). In development nothing is delivered: each email, including the confirmation link, is printed in `log/development.log` (search for `verify_email`; links use port 3000, as `bin/dev` does). In production set the `SMTP_*` and `MAILER_FROM` variables (see [Deploy](#3-set-the-environment)).

### Billing

Pro is sold through a payment provider behind one interface, `Billing::Provider` (`app/services/billing/`): `create_checkout(user:, plan:, interval:, currency:)` returns the hosted checkout URL, `portal_url(subscription)` the page where subscribers update their card or cancel, and `verify_webhook(headers, body)` turns a signed webhook into a `Billing::Event`. `Billing::WebhookReceiver` applies events to `Subscription` and keeps `users.plan` in step.

- **Development and tests** use `Billing::FakeProvider`: "Upgrade" opens a local test checkout, and "Pay" sends a webhook signed exactly like a real one through the same code path, so the whole flow works offline. It is never available in production.
- **Production** uses `Billing::Dodo` ([Dodo Payments](https://docs.dodopayments.com), merchant of record: it charges, files GST/VAT and pays out).
- **`Billing::Razorpay`** ([Razorpay Subscriptions](https://razorpay.com/docs/api/payments/subscriptions/)) is the fallback, or the rupee provider: Dodo pays out only in USD/EUR/GBP, so `BILLING_PROVIDER_INR=razorpay` sends INR checkouts to Razorpay while USD stays with Dodo. With Razorpay you are the seller of record and handle GST yourself. It has no customer portal, so subscribers cancel from settings (renewal stops at the end of the paid cycle). Its webhooks are an HMAC-SHA256 hex digest of the raw body in `X-Razorpay-Signature`, made idempotent with `x-razorpay-event-id`; point them at `https://APP_HOST/webhooks/billing/razorpay` with the `subscription.*` events.
- Prices come from `config/plans.yml`: ₹199/month and ₹1,499/year (shown **including GST**), $6/month and $48/year. Visitors from India (`CF-IPCountry: IN` or an `*-IN` browser language) see rupees, others dollars, and settings has an INR/USD toggle.

**Webhooks.** `POST /webhooks/billing/:provider` needs no session or CSRF token; the signature proves the request is genuine. Dodo signs with [Standard Webhooks](https://www.standardwebhooks.com/) (`webhook-id`, `webhook-timestamp`, `webhook-signature`, HMAC-SHA256, compared in constant time) and requests more than 5 minutes old are rejected. Each event id is stored in `webhook_events` with a unique index, so a retried delivery returns 200 without being applied again. Subscriptions move through these states:

| Event | Subscription | Plan |
|---|---|---|
| active, renewed | `active` | Pro |
| payment failed (on hold, past due) | `past_due` | Pro for 3 more days, then Free |
| cancelled | `canceled` | Pro until the paid period ends |
| expired | `expired` | Free |

Events older than one already applied are skipped. `BillingReconcileJob` runs daily at 4:30am UTC (`config/recurring.yml`) in case a webhook was missed: it expires cancelled subscriptions whose period is over, re-syncs plans after the grace period, and logs active subscriptions whose renewal never arrived.

Set up Dodo: create four **subscription products** (Pro monthly and yearly, in INR and in USD; mark the INR ones tax-inclusive), copy their ids into the variables below, and add a webhook endpoint pointing at `https://APP_HOST/webhooks/billing/dodo`. Test mode and live mode have separate keys, products and webhooks.

| Variable | Purpose |
|---|---|
| `BILLING_PROVIDER` | `fake`, `dodo` or `razorpay`. Defaults to `dodo` in production and `fake` elsewhere (`fake` is refused in production). |
| `DODO_API_KEY` | Dodo API key (secret). Without it, or any product id, Upgrade buttons are hidden. |
| `DODO_WEBHOOK_SECRET` | The endpoint's signing secret (`whsec_...`, secret). |
| `DODO_ENVIRONMENT` | `test_mode` (default, `test.dodopayments.com`) or `live_mode` (`live.dodopayments.com`). |
| `DODO_PRODUCT_PRO_MONTHLY_INR`, `DODO_PRODUCT_PRO_YEARLY_INR`, `DODO_PRODUCT_PRO_MONTHLY_USD`, `DODO_PRODUCT_PRO_YEARLY_USD` | Dodo product id (`pdt_...`) for each price. |
| `BILLING_PROVIDER_INR`, `BILLING_PROVIDER_USD` | Optional per-currency override of `BILLING_PROVIDER`, e.g. `razorpay` for rupees. |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Razorpay API keys (the secret is secret). |
| `RAZORPAY_WEBHOOK_SECRET` | The secret you set on the Razorpay webhook (secret). |
| `RAZORPAY_PLAN_PRO_MONTHLY_INR`, `RAZORPAY_PLAN_PRO_YEARLY_INR` | Razorpay plan ids (`plan_...`, create them at ₹199/month and ₹1,499/year incl. GST). `..._USD` variants are optional. |

### Run tests and checks

```bash
bin/rails test            # models, controllers, jobs, views
bin/rails test:system     # browser tests in headless Chrome
bin/rubocop
bin/brakeman --no-pager
bin/importmap audit
```

System tests use headless Chrome, and Selenium finds a matching driver by itself. To use a specific Chrome or Chromium build, point the tests at it:

```bash
CHROME_BIN=/path/to/chrome CHROMEDRIVER_PATH=/path/to/chromedriver bin/rails test:system
# add CHROME_NO_SANDBOX=1 when running as root, e.g. inside a container
```

## Policy pages: review before launch

> **⚠️ Megha must read and adjust these before taking payments. They are a plain-English starting point, not legal advice.**

`/privacy`, `/terms`, `/refunds` and `/contact` are written for an individual operator in India (DPDP Act 2023 and DPDP Rules 2025 notice basics, GDPR basics) with these subprocessors: Google Gemini API, Hetzner (hosting), Resend (email) and Dodo Payments (merchant of record). Before launch:

- Set `LEGAL_OWNER_NAME` and `SUPPORT_EMAIL`. Until both are set, every policy page shows a "Placeholder details" warning.
- Check the commitments match how you run things: 7-day first-payment refund, 3-day grace after a failed payment, 30-day backup deletion, replies within 2 working days, grievances acknowledged in 3 working days.
- Confirm the Gemini key is on the paid tier (the privacy page says prompts aren't used for training), and that the hosting region and email provider match the table.
- Bump `Legal::LAST_UPDATED` (`app/models/legal.rb`) whenever the wording changes.

## Deploy

Path Aviator runs as one Docker container on one small VPS, deployed with [Kamal 2](https://kamal-deploy.org). The container serves the app with Puma behind Thruster and runs the Solid Queue jobs inside Puma (`SOLID_QUEUE_IN_PUMA`). The SQLite databases live on a persistent Docker volume. `kamal-proxy` in front handles HTTPS with a free Let's Encrypt certificate and only sends traffic to a new version once `/up` answers.

Nothing server-specific is committed: `config/deploy.yml` reads the server, registry and domain from your shell, and `.kamal/secrets` reads the secrets from your shell.

### 1. What you need

- A VPS with Ubuntu 24.04, 1–2 GB RAM and your SSH key, for example a Hetzner Cloud CX22 or a DigitalOcean Basic droplet. Allow ports 22, 80 and 443 in its firewall. Kamal installs Docker on it for you.
- A domain or subdomain you can add DNS records to.
- A container registry account: Docker Hub with an [access token](https://docs.docker.com/security/for-developers/access-tokens/), or GitHub's `ghcr.io` with a token that has `write:packages`.
- Docker on your own machine (Kamal builds the `amd64` image there; on Apple Silicon this is emulated and slower).
- `config/master.key`. If you don't have it, run `rm config/credentials.yml.enc && bin/rails credentials:edit` to create a new key; the app keeps nothing else in credentials.

### 2. Point your domain at the server

Add an `A` record, for example `pathaviator.example.com → 203.0.113.10`, and wait until `dig +short pathaviator.example.com` shows the server's IP. Let's Encrypt checks this during the first deploy. On Cloudflare, use "DNS only" (grey cloud) or set SSL/TLS to "Full".

### 3. Set the environment

| Variable | Required | Used by | What it is |
|---|---|---|---|
| `KAMAL_SERVER_IP` | Yes | `deploy.yml` | The VPS's public IP address |
| `KAMAL_REGISTRY_USERNAME` | Yes | `deploy.yml` | Registry user; the image is pushed as `<user>/path_aviator` |
| `KAMAL_REGISTRY_PASSWORD` | Yes | secret | Registry access token |
| `KAMAL_REGISTRY_SERVER` | No | `deploy.yml` | Registry host, e.g. `ghcr.io`. Docker Hub when unset |
| `APP_HOST` | Yes | `deploy.yml`, app | Your domain: the HTTPS certificate, links in emails and Rails host checks |
| `RAILS_MASTER_KEY` | Yes | secret | Contents of `config/master.key` |
| `GEMINI_API_KEY` | No | secret | Real AI generation. Without it the built-in sample generator is used |
| `SEED_DEMO` | No | app | `1` creates the public demo account and resets it on every boot and every night. Default `0`: no demo account in production |
| `DEMO_EMAIL` | No | app | Sign-in email of the demo account. Defaults to `demo@pathaviator.dev` |
| `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME` | No | app | Outgoing email for address confirmation and password resets. Port defaults to 587. Without it new accounts can't confirm their email, so they stay at one path |
| `SMTP_PASSWORD` | No | secret | SMTP password or API key |
| `MAILER_FROM` | No | app | Sender address. Defaults to `Path Aviator <no-reply@APP_HOST>` |
| `LEGAL_OWNER_NAME` | Yes, before launch | app | Your legal name, shown as the operator and grievance officer on the policy pages |
| `LINKEDIN_ORGANIZATION_ID` | No | app | Your LinkedIn company page ID. When set, "Add to LinkedIn" on certificates links to that page instead of using the plain name "Path Aviator" |
| `SUPPORT_EMAIL` | Yes, before launch | app | The monitored support and grievance address shown on the policy and contact pages |
| `ADMIN_EMAILS` | No | app | Comma-separated emails that can open `/admin`. Everyone else gets a 404 there |
| `ERROR_REPORTER` | No | app | Where `Rails.error` reports go. `log` (default) writes `[ErrorReporter]` lines to the log |
| `BACKUP_DIR` | No | app | Folder for the nightly SQLite backup (e.g. a second volume). No backups without it |
| `BACKUP_KEEP` | No | app | How many nightly backups to keep. Default 7 |
| `AI_USD_PER_MILLION_TOKENS` | No | app | Price used for the admin page's AI cost estimate. Default 1.5 |
| `AI_DAILY_GENERATION_LIMIT` | No | app | Global cap on AI generations per UTC day. Default `500` |
| `GEMINI_THINKING_BUDGET` | No | app | Cap on Gemini thinking tokens. Default `1024` |
| `BILLING_PROVIDER` | No | app | Payment provider, default `dodo` (see [Billing](#billing)) |
| `DODO_API_KEY`, `DODO_WEBHOOK_SECRET` | For payments | secret | Dodo Payments API key and webhook signing secret |
| `DODO_ENVIRONMENT` | No | app | `test_mode` (default) or `live_mode` |
| `DODO_PRODUCT_PRO_{MONTHLY,YEARLY}_{INR,USD}` | For payments | app | Dodo product id for each of the four prices |
| `BILLING_PROVIDER_INR`, `BILLING_PROVIDER_USD` | No | app | Per-currency provider, e.g. `razorpay` for INR |
| `RAZORPAY_KEY_ID`, `RAZORPAY_PLAN_PRO_{MONTHLY,YEARLY}_INR` | For Razorpay | app | Razorpay key id and plan ids |
| `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` | For Razorpay | secret | Razorpay key secret and webhook secret |

Keep them in a file that git ignores (the `/.env*` rule covers `.env.deploy`) and load it before each Kamal command:

```bash
# .env.deploy (never commit this file)
export KAMAL_SERVER_IP=203.0.113.10
export KAMAL_REGISTRY_USERNAME=your-docker-hub-user
export KAMAL_REGISTRY_PASSWORD=your-access-token
export APP_HOST=pathaviator.example.com
export RAILS_MASTER_KEY=$(cat config/master.key)
export GEMINI_API_KEY=your-gemini-key   # optional
export SEED_DEMO=1                      # optional: public demo
```

```bash
source .env.deploy
```

### 4. First deploy

```bash
bin/kamal setup
```

This installs Docker on the server, builds and pushes the image, starts `kamal-proxy`, gets the certificate and boots the app. On boot, `bin/docker-entrypoint` runs `db:prepare` (plus `db:seed` when `SEED_DEMO=1`). Check it:

```bash
curl https://pathaviator.example.com/up   # 200 when the app is healthy
bin/kamal smoke                            # one real Gemini call, nothing saved
```

### 5. The demo account

In production the demo account (`demo@pathaviator.dev` / `pathaviator-demo`) is opt-in, so a private install never gets a login everyone knows. Deploy with `SEED_DEMO=1` to create it and reset it on every boot, or run `bin/kamal seed` to create or reset it once.

With `SEED_DEMO=1`, `ResetDemoAccountJob` also runs every night at 3am UTC (`config/recurring.yml`): progress, notes and sharing go back to the seeded state, and paths visitors added are deleted. Visitors can't lock others out: the demo account's settings (name, email, password, deletion) are refused by the server, and a password reset request for it sends nothing.

To remove it later (and unset `SEED_DEMO`):

```bash
bin/kamal console
User.find_by(email_address: DemoAccount.email)&.destroy
```

### 6. Day to day

| Command | What it does |
|---|---|
| `bin/kamal deploy` | Ship the committed code (Kamal builds from the current git commit) |
| `bin/kamal logs` | Follow the app logs |
| `bin/kamal console` | Rails console on the server |
| `bin/kamal rollback <version>` | Go back to an earlier image (see `bin/kamal app images`) |

With `BACKUP_DIR` set, `DatabaseBackupJob` writes a consistent copy of the database there every night at 2:30am UTC (`VACUUM INTO`) and keeps the newest `BACKUP_KEEP`. Point it at a second volume or a mounted disk, and copy that off the server.

Everything the app stores is in the `path_aviator_storage` volume (`/var/lib/docker/volumes/path_aviator_storage/_data` on the server). Turn on your provider's server backups, or copy a consistent snapshot with `bin/kamal app exec --reuse "sqlite3 storage/production.sqlite3 '.backup storage/backup.sqlite3'"` and download it.

### Try the production image locally

```bash
docker build -t path_aviator .
docker run --rm -p 8080:80 -e SECRET_KEY_BASE=$(openssl rand -hex 64) -e SOLID_QUEUE_IN_PUMA=true -e SEED_DEMO=1 path_aviator
curl http://localhost:8080/up
```

## Author

**Megha Koshti**, Ruby on Rails developer · [GitHub](https://github.com/MeghaKoshti) · [LinkedIn](https://www.linkedin.com/in/megha-koshti)

## License

[MIT](LICENSE)

# 🚀 Path Aviator

[![CI](https://github.com/MeghaKoshti/path-aviator/actions/workflows/ci.yml/badge.svg)](https://github.com/MeghaKoshti/path-aviator/actions/workflows/ci.yml)

**Path Aviator is an AI-powered learning planner built with Ruby on Rails 8.** Tell it what you want to learn, your current level and the hours you have each week. It plans a step-by-step route of courses, docs, videos, articles and practice, then tracks your progress as you tick steps off.

![A Path Aviator learning path for Ruby on Rails, three of eight steps done, with progress and time left](docs/screenshots/path.jpg)

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
| CI: tests, system tests, RuboCop, Brakeman, importmap audit | ✅ Done |
| Google / GitHub sign-in | 📝 Planned |

## Screenshots

<table>
  <tr>
    <td width="50%"><b>Landing</b><br><img src="docs/screenshots/landing.jpg" alt="Landing page: hero with a sample route and the three how-it-works steps"></td>
    <td width="50%"><b>Dashboard</b><br><img src="docs/screenshots/dashboard.jpg" alt="Dashboard with a finished Git path and a Rails path at 38 percent"></td>
  </tr>
  <tr>
    <td><b>Onboarding</b><br><img src="docs/screenshots/onboarding.jpg" alt="Onboarding step two of three: choosing the starting level"></td>
    <td><b>Learning path</b><br><img src="docs/screenshots/path.jpg" alt="Learning path with ticked steps, progress and the next step highlighted"></td>
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

### Background jobs

- **Development:** jobs run inside the Rails server (Active Job `:async` adapter), so `bin/dev` is all you need. Live updates use the in-process Action Cable adapter.
- **Production:** jobs run on Solid Queue. `config/deploy.yml` sets `SOLID_QUEUE_IN_PUMA=true` so one container serves web and jobs. To run a separate worker, use `bin/jobs`.

### AI generation (optional)

| Variable | Purpose |
|---|---|
| `GEMINI_API_KEY` | Enables real path generation with Google Gemini. Leave it unset to use the built-in sample generator. |
| `GEMINI_MODEL` | Model name, defaults to `gemini-2.5-flash`. |

```bash
GEMINI_API_KEY=your-key bin/dev
```

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
| `SEED_DEMO` | No | app | `1` creates the public demo account and resets it on every boot. Default `0`: no demo account in production |
| `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME` | No | app | Outgoing email for password resets. Port defaults to 587 |
| `SMTP_PASSWORD` | No | secret | SMTP password or API key |
| `MAILER_FROM` | No | app | Sender address. Defaults to `Path Aviator <no-reply@APP_HOST>` |

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

In production the demo account (`demo@pathaviator.dev` / `pathaviator-demo`) is opt-in, so a private install never gets a login everyone knows. Deploy with `SEED_DEMO=1` to create it and reset its progress on every boot, or run `bin/kamal seed` to create or reset it once. To remove it later (and unset `SEED_DEMO`):

```bash
bin/kamal console
User.find_by(email_address: "demo@pathaviator.dev")&.destroy
```

### 6. Day to day

| Command | What it does |
|---|---|
| `bin/kamal deploy` | Ship the committed code (Kamal builds from the current git commit) |
| `bin/kamal logs` | Follow the app logs |
| `bin/kamal console` | Rails console on the server |
| `bin/kamal rollback <version>` | Go back to an earlier image (see `bin/kamal app images`) |

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

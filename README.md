# 🚀 Path Aviator

[![CI](https://github.com/MeghaKoshti/path-aviator/actions/workflows/ci.yml/badge.svg)](https://github.com/MeghaKoshti/path-aviator/actions/workflows/ci.yml)

**Path Aviator is an AI-powered learning platform (in progress) built with Ruby on Rails 8.** The goal: tell it what you want to learn, and it builds a structured learning path from YouTube videos, docs, blogs, GitHub repos and courses, then tracks your progress.

![Path Aviator sign-in page](docs/screenshots/sign-in.jpg)

## Status

| Area | Status |
|---|---|
| Rails 8 app setup (Solid Queue, Solid Cache, Kamal) | ✅ Done |
| Authentication (Rails 8 built-in: sessions, password reset) | ✅ Done |
| Design system, landing page and app shell (Tailwind CSS) | ✅ Done |
| Sign-up page | 🚧 In progress (route exists, controller next) |
| Google / GitHub sign-in | 📝 Planned |
| AI onboarding to detect skills and interests | 📝 Planned |
| Personalised learning playlists | 📝 Planned |
| Bookmarks, progress tracking, smart resume | 📝 Planned |

## Tech stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails 8.0 |
| Auth | Rails 8 authentication generator (`has_secure_password`, sessions) |
| Frontend | Hotwire (Turbo + Stimulus) with Importmap |
| Styling | Tailwind CSS (`tailwindcss-rails`) |
| Database | SQLite |
| Background jobs | Solid Queue |
| Caching | Solid Cache |
| Assets | Propshaft + Thruster |
| Deployment | Kamal (Docker) |

## Getting started

### Prerequisites

- Ruby 3.3 (see `.ruby-version`)
- No Node.js needed (Importmap + `tailwindcss-rails`)

### Setup

```bash
git clone git@github.com:MeghaKoshti/path-aviator.git
cd path-aviator

bundle install
bin/rails db:prepare

bin/dev          # runs the Rails server + Tailwind watcher
```

Open http://localhost:3000.

### Run tests

```bash
bin/rails test
```

## Author

**Megha Koshti**, Ruby on Rails developer · [GitHub](https://github.com/MeghaKoshti) · [LinkedIn](https://www.linkedin.com/in/megha-koshti)

## License

[MIT](LICENSE)

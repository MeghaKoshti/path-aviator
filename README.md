# 🚀 Path Aviator

**Path Aviator** is a robust AI-driven personalized learning platform, built with Ruby on Rails 8. It intelligently curates structured learning paths based on users’ interests, skills, and goals—aggregating content across platforms like YouTube, blogs, GitHub, and more.

---

## 🧠 Core Features

- 🔍 **AI-powered onboarding** for skill/interest detection  
- 📚 **Dynamic learning playlists** tailored to user context  
- 🔗 **Integrated content sources** (videos, docs, repos, blogs, courses)  
- 🏷️ **Bookmarking, progress tracking, and smart resume**  
- ⚡ **Reactive frontend** via Hotwire (Turbo + Stimulus)  
- 🧘‍♀️ **Minimalist UI** styled with Tailwind CSS

---

## 🛠 Tech Stack

| Layer        | Technology                       |
|--------------|----------------------------------|
| Backend      | Ruby on Rails 8.0.2              |
| Frontend     | Hotwire (Turbo + Stimulus)       |
| Styling      | Tailwind CSS (via Importmap + ESM)|
| Database     | PostgreSQL (default), SQLite (dev)|
| Job Queue    | Solid Queue                      |
| Caching      | Solid Cache                      |
| Asset Pipeline | Propshaft + Thruster           |
| Deployment   | Kamal (Dockerized deploy)        |
| Debugging    | Web Console, Debug gem           |

---

## 🚧 Getting Started

### ✅ Prerequisites

Make sure the following are installed:

- **Ruby 3.2+** (recommended: 3.3.x) — via `rbenv` or `rvm`  
- **Rails 8.0.2+**
- **PostgreSQL** (or SQLite for local dev only)  
- **Node.js & Yarn** (for Tailwind + Hotwire dependencies)

---

### 📦 Setup Instructions

```bash
# Clone the repository
git clone git@github.com:MeghaKoshti/path-aviator.git
cd path-aviator

# Install dependencies
bundle install
yarn install

# Setup the database
rails db:create db:migrate db:seed

# Run the app
rails server

# Path Aviator

A robust, AI-driven personalized learning platform built with Ruby on Rails 8. Path Aviator intelligently curates structured learning paths based on a user’s interests, skill level, and learning goals.

---

## 🚀 Features

- Intelligent onboarding with AI-based skill and interest profiling  
- Dynamically generated learning playlists tailored to user needs  
- Integration with diverse learning sources (e.g., video platforms, blogs, repositories)  
- Bookmarking, progress tracking, and resume learning support  
- Clean UI built with Hotwire (Turbo + Stimulus) and Tailwind CSS  

---

## 🧱 Tech Stack

- **Ruby on Rails 8** (Unified backend and frontend)  
- **Hotwire (Turbo + Stimulus)** for reactive UI  
- **Tailwind CSS** for utility-first styling  
- **PostgreSQL** for primary data store  
- Built-in Rails tools: Solid Queue, Action Mailer, Action Text, etc.

---

## 🚧 Getting Started

### Prerequisites

- **Ruby 3.2.x+** (managed via rbenv or rvm)  
- **PostgreSQL**  
- **Node.js & Yarn** (for Tailwind & asset pipeline)

### Setup the Project

```bash
git clone git@github.com:MeghaKoshti/path-aviator.git
cd path-aviator
bundle install
yarn install
rails db:create db:migrate
bin/dev

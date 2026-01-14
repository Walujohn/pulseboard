# PulseBoard

A small Rails 8 warmup application built to practice:

- TDD API development using Minitest
- RESTful JSON APIs
- Hotwire (Turbo Frames & Turbo Streams)
- Stimulus controllers (React → Hotwire migration style)
- PostgreSQL with ActiveRecord

## Features
- Create, list, update, delete status updates
- JSON API under `/api/v1/status_updates`
- Hotwire-powered UI (no page reloads)
- Stimulus-powered “Like” button

## Tech Stack
- Ruby 3.4
- Rails 8
- PostgreSQL
- Minitest
- Hotwire (Turbo + Stimulus)

## Setup
```bash
bundle install
rails db:prepare
rails server

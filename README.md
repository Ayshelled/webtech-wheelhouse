# Wheelhouse

Wheelhouse is a neighbourhood bicycle repair shop. This project contains the public-facing shop site with four pages: home, services, visiting the workshop, and about.

Documentation for the project lives in the docs directory.

## Prerequisites

- Ruby 3.3.5
- Rails 8.1.3
- Node 20.19.0 or newer
- PostgreSQL 16
- Bundler

## Setup

1. Clone the repository.
2. Install the Ruby gems:
   ```bash
   bundle install
   ```
3. Install the JavaScript dependencies:
   ```bash
   npm install
   ```
4. Create the local PostgreSQL databases:
   ```bash
   bin/rails db:create
   ```
5. Start the app:
   ```bash
   bin/dev
   ```

## Start the application

Run:

```bash
bin/dev
```

Then open http://localhost:3000 in your browser.

## Project docs

- [docs/](docs/)

## Notes

This site is intentionally static and does not use a database-backed model layer for this lab.

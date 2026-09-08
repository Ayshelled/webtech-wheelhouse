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
2. Install dependencies:

   ```bash
   bundle install
   npm install
   ```

3. Create the database, load the schema, and seed the data:

   ```bash
   bin/rails db:setup
   ```

4. Start the app:

   ```bash
   bin/dev
   ```

## Start the application

Run:

```bash
bin/dev
```

Then open http://localhost:3000 in your browser.


- [docs/](docs/)

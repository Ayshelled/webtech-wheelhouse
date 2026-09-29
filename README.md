# Wheelhouse

Wheelhouse is a neighbourhood bicycle repair shop. This project contains the public-facing shop site with four pages: home, services, visiting the workshop, and about.

Documentation for the project lives in the docs directory.

## Prerequisites

- Ruby 3.4.10 (see `.ruby-version`)
- Rails 8.1.3.1 or newer in the 8.1 series
- Node.js 24.20.0 and npm
- PostgreSQL 16, running locally
- Bundler

## Setup

1. Clone the repository and enter its directory.
2. Install Ruby and JavaScript dependencies:

   ```bash
   bundle install
   npm install
   ```

3. Ensure PostgreSQL is running and that your local PostgreSQL role can create databases. If your role or connection differs from the defaults, set `DATABASE_URL` to a PostgreSQL connection URL before running Rails commands.
4. Create the database, load the schema, and seed the data:

   ```bash
   bin/rails db:setup
   ```

5. Start the app:

   ```bash
   bin/dev
   ```

## Run the application

Run:

```bash
bin/dev
```

Then open http://localhost:3000 in your browser.


- [docs/](docs/)

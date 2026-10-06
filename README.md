# Wheelhouse

Wheelhouse is a neighbourhood bicycle repair shop. This project contains the public-facing shop site with four pages: home, services, visiting the workshop, and about.

Documentation for the project lives in the docs directory.

## Prerequisites

- Ruby 3.4.10 (see `.ruby-version`)
- Rails 8.1.3.1 or newer in the 8.1 series
- Node.js 24.20.0 and npm
- PostgreSQL 16, running locally
- libvips, used to generate Active Storage image variants:
  - Ubuntu/Debian: `sudo apt-get update && sudo apt-get install -y libvips`
  - macOS with Homebrew: `brew install vips`
- Bundler

## Setup

1. Clone the repository and enter its directory.
2. Install Ruby and JavaScript dependencies:

   ```bash
   bundle install
   npm install
   ```

3. Ensure PostgreSQL is running and that your local PostgreSQL role can create databases. If your role or connection differs from the defaults, set `DATABASE_URL` to a PostgreSQL connection URL before running Rails commands.
4. Create the database, load the schema, and seed the data (including repair photos):

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

The repairs index is seeded with intake-photo thumbnails. Uploaded development files
are stored locally under `storage/`; that directory is ignored by Git. Seed images
remain in `db/seeds/`.

The bicycle seed images are CC0/Public Domain Mark images:

- “The Red Bicycle.” by Bernard Spragg — https://www.flickr.com/photos/88123769@N02/15655615295
- “Bombay Bicycle Club? Penny farthings and other vintage cycles in India, c. 1890” by whatsthatpicture — https://www.flickr.com/photos/24469639@N00/2992330426
- “Demolished bicycle on the bridge at the end of Kinkerstraat” by Amsterdam free photos & pictures of the Dutch city — https://www.flickr.com/photos/104736837@N03/10903156366
- “A bicycle wheel in the snow” by Amsterdam free photos & pictures of the Dutch city — https://www.flickr.com/photos/104736837@N03/27625575802


- [docs/](docs/)

# Bidding Website

A freelance marketplace built with Ruby on Rails. Clients post gigs, freelancers bid on them with proposals, the client awards a proposal, and the freelancer delivers the work as uploaded solutions.

## Features

- **Accounts**: sign-up as a Client or Freelancer, email account activation, password reset, optional "remember me" login.
- **Gigs**: clients post gigs with a budget, location, category, skills and file attachments. Anyone can browse, sort and search them by keyword or category.
- **Proposals**: freelancers bid on gigs; the gig owner awards one proposal.
- **Solutions**: freelancers upload up to three files per solution against their proposal; the gig owner reviews them.
- **Messaging**: user-to-user conversations with per-user unread and trash state.
- **Notifications**: in-app notifications for new proposals, awarded gigs and new conversations.
- **Admin**: admins can edit or delete any gig, list all proposals, and activate, deactivate or delete other users. Deactivated users are logged out and cannot log in.

## Tech stack

| | |
|---|---|
| Language | Ruby 3.3.12 |
| Framework | Rails 8.1 |
| Database | MySQL 8 (development and test) |
| Uploads | CarrierWave + MiniMagick (ImageMagick) |
| Front end | Sprockets, Bootstrap 3 (`bootstrap-sass`), jQuery |
| Tests | Minitest |
| Lint | RuboCop with `rubocop-rails` and `rubocop-minitest` |

## Getting started with Docker (recommended)

Requirements: Docker with the Compose plugin.

```bash
git clone https://github.com/Nitish313/bidding_website.git
cd bidding_website

docker compose build
docker compose up -d db
docker compose run --rm web bin/rails db:setup   # create, load schema, seed
docker compose up web
```

Open <http://localhost:3000>.

MySQL runs in its own container and is not published on the host, so it does not clash with a local MySQL on port 3306.

The app container runs as user and group 1000, so files it writes into the project (logs, caches, uploads) belong to you, not root. If your user or group id is not 1000 (check with `id -u` and `id -g`), set `HOST_UID` and `HOST_GID` in `.env`.

### Emails in development

Outgoing emails (account activation, password reset) are not sent. They are captured by [letter_opener_web](https://github.com/fgrehm/letter_opener_web) and can be read at <http://localhost:3000/letter_opener>. After signing up you are redirected there to click the activation link.

### Seed data

`db:seed` creates the job categories and an activated admin user. It is safe to run more than once.

The admin's email and password come from `SEED_ADMIN_EMAIL` (default `admin@example.com`) and `SEED_ADMIN_PASSWORD`. If no password is set, a random one is generated and printed when the admin is created. To choose your own, copy `.env.example` to `.env` and fill it in before seeding; `docker compose` passes `.env` to the app container, and git ignores it.

### Health check and logs

`GET /health` returns `{"status":"ok","database":"ok"}` when the app can reach its database, and HTTP 503 with `"database":"unavailable"` when it cannot. It needs no login, so load balancers and uptime monitors can poll it.

Outside development, each request is logged as a single JSON line ([lograge](https://github.com/roidrage/lograge), configured in [config/initializers/lograge.rb](config/initializers/lograge.rb)) with method, path, status, duration and `request_id`. Health checks are left out of the log. Set `RAILS_LOG_TO_STDOUT=1` to log to standard output, for example in a container.

### Error tracking

In production, unexpected errors are reported to [Sentry](https://sentry.io) (or a Sentry-compatible service such as GlitchTip) when `SENTRY_DSN` is set; without it nothing is sent. Development and test runs never report, even with `SENTRY_DSN` in `.env`. Reports carry the logged-in user's id but no personal data. Routine errors such as missing records (404) and malformed requests (400) are not reported. Optional: `SENTRY_TRACES_SAMPLE_RATE` (0 to 1) for performance tracing and `SENTRY_RELEASE` to tag reports with a version.

## Running the tests

```bash
docker compose up -d db
docker compose run --rm -e RAILS_ENV=test web bin/rails db:create db:schema:load   # first time only
docker compose run --rm -e RAILS_ENV=test web bin/rails test
```

Each run writes a coverage report to `coverage/index.html` (git-ignored). The run fails if line coverage drops below the minimum set in [.simplecov](.simplecov), and CI checks it again as its own **Check coverage minimum** step (`bin/check-coverage`), which also shows the coverage and the minimum in the job summary on the run's page. CI uploads the report as a `coverage` artifact on every run.

Run a single file, or a single test by its line number:

```bash
docker compose run --rm -e RAILS_ENV=test web bin/rails test test/models/gig_test.rb
docker compose run --rm -e RAILS_ENV=test web bin/rails test test/models/gig_test.rb:12
```

## Linting

```bash
docker compose run --rm --no-deps web bundle exec rubocop
```

Existing offenses are recorded in [.rubocop_todo.yml](.rubocop_todo.yml); new code must pass the full rules in [.rubocop.yml](.rubocop.yml). When you fix a recorded offense, remove its entry from the todo file.

## Continuous integration

[GitHub Actions](.github/workflows/ci.yml) runs on every pull request, every push to `master` and once a week, with these jobs:

- **test**: builds the Docker image, starts MySQL, loads the schema and runs the test suite.
- **lint**: runs RuboCop and checks that the app boots in development mode.
- **audit**: checks every gem in `Gemfile.lock` against the [Ruby Advisory Database](https://github.com/rubysec/ruby-advisory-db) with bundler-audit. The weekly run catches advisories published between pull requests.
- **production-image**: builds the production image and starts it against an empty MySQL the way Render does ([bin/smoke-test-production-image](bin/smoke-test-production-image)): the schema must load, `/health` must answer and a page must render.
- **deploy**: on pushes to `master` only, once all the jobs above pass, asks Render to deploy (see [Deploying](#deploying-render--aiven)).

Run the audit locally with:

```bash
docker compose run --rm --no-deps web bundle exec bundle-audit check --update
```

## Running without Docker

Requirements: Ruby 3.3.12, Bundler 2.5.22, MySQL, ImageMagick, Node.js (for asset compilation) and `shared-mime-info`.

```bash
gem install bundler -v 2.5.22
bundle install
bin/rails db:setup
bin/rails server
```

The database connection is configured with environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `DB_USERNAME` | `root` | MySQL user |
| `DB_PASSWORD` | empty | MySQL password |
| `DB_HOST` | unset | MySQL host; when unset, the local socket `/var/run/mysqld/mysqld.sock` is used |
| `DB_PORT` | `3306` | MySQL port, used only with `DB_HOST` |

## Deploying (Render + Aiven)

The app runs on [Render](https://render.com) from the production image in [Dockerfile.prod](Dockerfile.prod), with MySQL on [Aiven](https://aiven.io). Uploads go to S3-compatible object storage, because Render's disk is wiped on every deploy, and emails go out over SMTP. All four have free plans. [render.yaml](render.yaml) describes the service.

On start, the container runs `bin/rails db:prepare`: on an empty database it loads the schema and the seed data (categories and the admin account), and later it runs any new migrations.

One-time setup:

1. **Database:** create a MySQL service on Aiven and copy its **Service URI** (`mysql://avnadmin:…@….aivencloud.com:…/defaultdb?ssl-mode=REQUIRED`).
2. **Uploads:** create a bucket and an access key with read and write access to it, for example in Cloudflare R2 (**R2 → Create bucket**, then **Manage R2 API tokens**). Keep the bucket private; the app hands out signed links that expire after ten minutes.
3. **Email:** create an SMTP login with any provider (for example Brevo, Mailgun or a Gmail app password) and verify the sender address you will send from.
4. **Render:** choose **New → Blueprint**, pick this repository, and fill in the variables below when asked.
5. **Automatic deploys:** in the Render service, open **Settings → Deploy Hook** and copy the URL. In GitHub, add it as the repository secret `RENDER_DEPLOY_HOOK_URL` (**Settings → Secrets and variables → Actions**). From then on, CI deploys every push to `master` that passes all checks.

| Variable | Example | Purpose |
|---|---|---|
| `DATABASE_URL` | Aiven's Service URI | MySQL connection; encrypted unless `DB_SSL_MODE=disabled` |
| `SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD` | your own | Admin account created on the first start |
| `STORAGE_BUCKET` | `bidding-uploads` | Bucket for uploads; without it files are stored on the container's disk |
| `STORAGE_ENDPOINT` | `https://<account-id>.r2.cloudflarestorage.com` | S3 API endpoint; leave unset for AWS S3 |
| `STORAGE_ACCESS_KEY_ID`, `STORAGE_SECRET_ACCESS_KEY` | from the access key | Bucket credentials |
| `STORAGE_REGION` | `auto` (default) | Needed for AWS S3 only, for example `ap-south-1` |
| `SMTP_ADDRESS`, `SMTP_PORT` | `smtp-relay.brevo.com`, `587` | SMTP server; port defaults to 587 |
| `SMTP_USERNAME`, `SMTP_PASSWORD` | from the provider | SMTP login |
| `MAIL_FROM` | `Bidding Website <you@example.com>` | Sender of activation and password reset emails |
| `APP_HOST` | `bids.example.com` | Address used in email links; defaults to the Render address |
| `SENTRY_DSN` | from Sentry | Optional error reporting |

Render sets `SECRET_KEY_BASE` and `PORT` itself. To try the production image locally, run `bin/smoke-test-production-image`.

On the free plan, Render stops the app after 15 minutes without traffic, so the first request after a pause takes up to a minute.

## Contributing and changes

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to make and submit changes, [CHANGELOG.md](CHANGELOG.md) for what changed in each release, and [MAINTAINERS.md](MAINTAINERS.md) for who maintains the project and how.

## Project structure

```
app/
  controllers/   one controller per resource: users, sessions, account_activations,
                 password_resets, gigs, proposals, solutions, conversations,
                 messages, notifications, home
  models/        User, Gig, Category, Skill, Ability (gig-skill join), Proposal,
                 Solution, Notification
  mailers/       UserMailer: account activation and password reset
  uploaders/     CarrierWave uploaders for profile pictures and attachments
  helpers/       SessionsHelper: login, logout and remember-me cookies
config/          routes, environments, database.yml
db/              schema.rb, migrations, seeds.rb
test/            model, controller, helper, integration and mailer tests with fixtures
```

Main relationships:

- A **User** (Client) has many **Gigs**; a **Gig** belongs to a **Category** and has many **Skills** through **Abilities**.
- A **Gig** has many **Proposals**; each **Proposal** belongs to a freelancer **User**. The gig's `awarded_proposal` records the winning bid.
- A **Proposal** has many **Solutions** (file deliveries).
- **Notifications** are polymorphic (`notifiable`) and point at the gig, proposal or message that triggered them.

Access control is done with `before_action` filters in each controller (logged-in user, owner or admin, client-only or freelancer-only actions).

# Bidding Website

A freelance marketplace built with Ruby on Rails. Clients post gigs, freelancers bid on them with proposals, the client awards a proposal, and the freelancer delivers the work as uploaded solutions.

## Features

- **Accounts**: sign-up as a Client or Freelancer, email account activation, password reset, optional "remember me" login.
- **Gigs**: clients post gigs with a budget, location, category, skills and file attachments. Anyone can browse, sort and search them by keyword or category.
- **Proposals**: freelancers bid on gigs; the gig owner awards one proposal.
- **Solutions**: freelancers upload up to three files per solution against their proposal; the gig owner reviews them.
- **Messaging**: user-to-user conversations (via the [mailboxer](https://github.com/mailboxer/mailboxer) gem).
- **Notifications**: in-app notifications for new proposals, awarded gigs and new conversations.
- **Admin**: admins can edit or delete any gig, list all proposals, and activate, deactivate or delete other users. Deactivated users are logged out and cannot log in.

## Tech stack

| | |
|---|---|
| Language | Ruby 2.7.2 |
| Framework | Rails 5.2 |
| Database | MySQL 8 (development and test) |
| Uploads | CarrierWave + MiniMagick (ImageMagick) |
| Front end | Sprockets, Bootstrap 3 (`bootstrap-sass`), jQuery, CoffeeScript |
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

In production, each request is logged as a single JSON line ([lograge](https://github.com/roidrage/lograge)) with method, path, status, duration and `request_id`. Health checks are left out of the log. Set `RAILS_LOG_TO_STDOUT=1` to log to standard output, for example in a container.

## Running the tests

```bash
docker compose up -d db
docker compose run --rm -e RAILS_ENV=test web bin/rails db:create db:schema:load   # first time only
docker compose run --rm -e RAILS_ENV=test web bin/rails test
```

Each run writes a coverage report to `coverage/index.html` (git-ignored). The run fails if line coverage drops below the minimum set in [test/test_helper.rb](test/test_helper.rb). CI uploads the report as a `coverage` artifact on every run.

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

[GitHub Actions](.github/workflows/ci.yml) runs on every pull request and every push to `master`, with two jobs:

- **test**: builds the Docker image, starts MySQL, loads the schema and runs the test suite.
- **lint**: runs RuboCop.

## Running without Docker

Requirements: Ruby 2.7.2, Bundler 2.1.4, MySQL, ImageMagick, Node.js (for asset compilation) and `shared-mime-info`.

```bash
gem install bundler -v 2.1.4
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

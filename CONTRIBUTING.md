# Contributing

Thanks for helping improve Bidding Website. This guide covers how changes are made and reviewed.

## Setup

Follow [Getting started with Docker](README.md#getting-started-with-docker-recommended) in the README. Everything below runs inside the `web` container, so you do not need Ruby or MySQL installed locally.

## Making a change

1. Branch from an up-to-date `master`:
   ```bash
   git checkout master && git pull --ff-only origin master
   git checkout -b short-descriptive-name
   ```
2. Keep each pull request to one fix or feature.
3. Ship the change together with the tests that prove it, in the same commit. For a bug fix, write the failing test first, then the fix.
4. Keep refactors and formatting changes in separate commits from behaviour changes.

## Before opening a pull request

Run the same checks as CI:

```bash
docker compose up -d db
docker compose run --rm -e RAILS_ENV=test web bin/rails test
docker compose run --rm --no-deps web bundle exec rubocop
docker compose run --rm --no-deps web bundle exec bundle-audit check --update
```

- All tests must pass, and line coverage must stay above the minimum in [.simplecov](.simplecov).
- RuboCop must report no offenses. When you fix an offense listed in [.rubocop_todo.yml](.rubocop_todo.yml), remove its entry.
- If you change behaviour users or operators will notice, add a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md).

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): a type, a colon, and a short imperative summary of what changes.

```
type: summary in the imperative mood
```

| Type | Use for |
|---|---|
| `feat` | a new feature or user-visible behaviour |
| `fix` | a bug fix |
| `test` | adding or correcting tests only |
| `refactor` | code changes that do not change behaviour |
| `perf` | performance improvements |
| `docs` | documentation only |
| `build` | dependencies, Gemfile, Dockerfile |
| `ci` | GitHub Actions workflow changes |
| `chore` | anything else that does not touch app code |

Examples:

```
fix: return 422 when a gig form is invalid
feat: limit a gig's skill list to 20 skills
build: upgrade Rails to 8.1
```

A fix or feature and the tests that prove it go in the **same** commit. Explain *why* in the body when it is not obvious. Commits made before this convention was adopted use plain sentences.

## Pull requests

- CI must be green before merging.
- Merge with a merge commit, not a squash, so each focused commit stays in the history.
- Delete the branch after merging.

## Dependency updates

Dependabot opens weekly pull requests for gems and GitHub Actions. Merge them one at a time once CI is green, and check the changelog of any major version bump before merging.

## Releases

1. Move the **Unreleased** entries in [CHANGELOG.md](CHANGELOG.md) under a new version heading with the date.
2. After that change is merged, tag the release on `master`:
   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin vX.Y.Z
   ```

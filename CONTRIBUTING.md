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

- All tests must pass, and line coverage must stay above the minimum in [test/test_helper.rb](test/test_helper.rb).
- RuboCop must report no offenses. When you fix an offense listed in [.rubocop_todo.yml](.rubocop_todo.yml), remove its entry.
- If you change behaviour users or operators will notice, add a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md).

## Commit messages

Use the imperative mood and say what changes, for example `Validate gig awards against the gig's own proposals`. Explain *why* in the body when it is not obvious.

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

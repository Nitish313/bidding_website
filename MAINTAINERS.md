# Maintainers

## Current maintainer

| Maintainer | GitHub | Responsibilities |
|---|---|---|
| Nitish | [@Nitish313](https://github.com/Nitish313) | Code review, merging, releases, dependency updates |

The project has a single maintainer. This file records how it is maintained so that a
second maintainer can take over or share the work without relying on tribal knowledge.

## How the project is maintained

- **Every change goes through a pull request.** CI must pass before merging: tests with a
  96% coverage minimum, RuboCop, a gem vulnerability audit, a development-mode boot and a
  production asset precompile. See [CONTRIBUTING.md](CONTRIBUTING.md).
- **Pull requests are merged with merge commits**, so each focused commit stays in history.
- **Dependencies:** Dependabot opens weekly pull requests for gems and GitHub Actions, and
  the CI audit job runs every week to catch newly published advisories.
- **Releases:** follow [Semantic Versioning](https://semver.org/). Notable changes are
  added to the Unreleased section of [CHANGELOG.md](CHANGELOG.md) as they merge, then moved
  under a version heading and tagged (`vX.Y.Z`) when released.

## Onboarding a new maintainer

1. Get the app running and the test suite green with Docker, following the
   [README](README.md#getting-started-with-docker-recommended).
2. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the latest entries in
   [CHANGELOG.md](CHANGELOG.md).
3. Take a few Dependabot pull requests through review and merge to learn the CI checks.
4. Ship a small fix with its tests through a pull request, reviewed by the current
   maintainer.
5. Once comfortable, get write access and add yourself to the table above.

## Known areas to watch

- **Front-end assets** still use Sprockets with `sass-rails` (SassC, whose LibSass is deprecated), Bootstrap 3 and Turbolinks.
  Moving to `dartsass-sprockets` or Propshaft, Bootstrap 5 and Turbo are candidates for future work.

## Reporting a security issue

Please do not open a public issue. Use GitHub's
[private vulnerability reporting](https://github.com/Nitish313/bidding_website/security/advisories/new)
for this repository, or contact the maintainer through GitHub.

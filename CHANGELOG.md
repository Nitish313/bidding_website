# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Upgraded Rails 5.2 → 6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1, moving to each version's framework defaults in its own step ([#60](https://github.com/Nitish313/bidding_website/pull/60), [#62](https://github.com/Nitish313/bidding_website/pull/62), [#63](https://github.com/Nitish313/bidding_website/pull/63), [#64](https://github.com/Nitish313/bidding_website/pull/64), [#65](https://github.com/Nitish313/bidding_website/pull/65), [#66](https://github.com/Nitish313/bidding_website/pull/66)).
- Switched to the Zeitwerk autoloader ([#61](https://github.com/Nitish313/bidding_website/pull/61)).
- Upgraded Ruby 2.7 → 3.3 on a supported Debian (bookworm) base image, with Bundler 2.5 and Puma 6.
- Moving to the Rails 7.0 defaults rotates cookies to the new key derivation, so nobody is logged out ([#66](https://github.com/Nitish313/bidding_website/pull/66)).

### Fixed

- Production asset precompilation failed: Uglifier could not minify the modern JavaScript in Active Storage's script. JavaScript is now minified with Terser, and the unused Active Storage script is no longer loaded.

### Security

- Cleared every known gem vulnerability reported by bundler-audit: Rails 7.2.3.2, Puma 7.2, carrierwave 2.2.7 and jquery-rails 4.6, and removed unused browser-test gems ([#72](https://github.com/Nitish313/bidding_website/pull/72)).
- Cookies are sent with `SameSite=Lax`, CSRF tokens are URL-safe, and redirects never leave the site ([#64](https://github.com/Nitish313/bidding_website/pull/64), [#66](https://github.com/Nitish313/bidding_website/pull/66)).

### Removed

- Spring, the unused `faker` and `chromedriver-helper` gems, and the end-of-life `archive.debian.org` package source.

## [1.0.0] - 2026-10-15

First versioned release. The application itself dates from 2020; this release
brings it up to a maintained baseline: reproducible setup, CI, a real test suite
and a series of security and correctness fixes.

### Added

- Docker Compose setup for development and tests; the app container runs as the host user ([#29](https://github.com/Nitish313/bidding_website/pull/29), [#47](https://github.com/Nitish313/bidding_website/pull/47)).
- GitHub Actions CI running the test suite and RuboCop on every pull request ([#34](https://github.com/Nitish313/bidding_website/pull/34)).
- RuboCop with Rails and Minitest cops, with existing offenses recorded in `.rubocop_todo.yml` ([#33](https://github.com/Nitish313/bidding_website/pull/33)).
- README covering setup, tests, linting, CI and project structure ([#35](https://github.com/Nitish313/bidding_website/pull/35)).
- Test suite grown from generator stubs to 231 tests covering models, controllers, helpers and end-to-end flows ([#30](https://github.com/Nitish313/bidding_website/pull/30), [#43](https://github.com/Nitish313/bidding_website/pull/43), [#56](https://github.com/Nitish313/bidding_website/pull/56)).
- SimpleCov coverage report with a 96% minimum enforced in CI ([#55](https://github.com/Nitish313/bidding_website/pull/55), [#56](https://github.com/Nitish313/bidding_website/pull/56)).
- `GET /health` endpoint that checks the database ([#57](https://github.com/Nitish313/bidding_website/pull/57)).
- One JSON log line per request in production via lograge ([#57](https://github.com/Nitish313/bidding_website/pull/57)).
- Dependabot weekly updates for gems and GitHub Actions ([#50](https://github.com/Nitish313/bidding_website/pull/50)).
- `.env.example` documenting configuration ([#46](https://github.com/Nitish313/bidding_website/pull/46)).

### Changed

- Database settings and the seeded admin's credentials come from environment variables ([#29](https://github.com/Nitish313/bidding_website/pull/29), [#46](https://github.com/Nitish313/bidding_website/pull/46)).
- Deleting a conversation moves it to that user's trash instead of deleting it for both participants ([#42](https://github.com/Nitish313/bidding_website/pull/42)).
- Admins can still read other users' conversations and notifications but can only act from their own account ([#41](https://github.com/Nitish313/bidding_website/pull/41)).
- Owner-or-admin checks share one helper across controllers ([#49](https://github.com/Nitish313/bidding_website/pull/49)).
- Line endings normalised to LF and enforced with `.gitattributes` ([#44](https://github.com/Nitish313/bidding_website/pull/44)).
- The development server is published on localhost only ([#51](https://github.com/Nitish313/bidding_website/pull/51)).

### Fixed

- Signup crashed outside development ([#43](https://github.com/Nitish313/bidding_website/pull/43)).
- The password reset form crashed for every valid link ([#43](https://github.com/Nitish313/bidding_website/pull/43)).
- Gig pages crashed for logged-out visitors ([#43](https://github.com/Nitish313/bidding_website/pull/43)).
- "Remember me" never restored a session from its cookie ([#31](https://github.com/Nitish313/bidding_website/pull/31)).
- Saving a gig without a skill list crashed, and search returned `nil` with no criteria ([#32](https://github.com/Nitish313/bidding_website/pull/32)).
- Logged-out requests to delete a proposal or reply to a message crashed ([#39](https://github.com/Nitish313/bidding_website/pull/39)).
- Amounts, text lengths and roles are validated; oversized values no longer crash saves ([#58](https://github.com/Nitish313/bidding_website/pull/58)).
- `bin/` scripts were not executable on a fresh clone ([#29](https://github.com/Nitish313/bidding_website/pull/29)).

### Security

- Only admins can activate or deactivate users, and deactivated users lose their session immediately ([#36](https://github.com/Nitish313/bidding_website/pull/36)).
- Only the awarded freelancer can submit solutions for a proposal ([#37](https://github.com/Nitish313/bidding_website/pull/37)).
- Gig awards must be one of that gig's proposals and cannot be changed once made ([#38](https://github.com/Nitish313/bidding_website/pull/38)).
- Admins can no longer delete their own account ([#40](https://github.com/Nitish313/bidding_website/pull/40)).
- Admins can no longer send messages or change conversations as another user ([#41](https://github.com/Nitish313/bidding_website/pull/41)).
- A freelancer can bid once per gig, and only on open gigs ([#43](https://github.com/Nitish313/bidding_website/pull/43)).
- Removed the hardcoded seed admin password ([#46](https://github.com/Nitish313/bidding_website/pull/46)).
- Updated rack, nokogiri, loofah, rails-html-sanitizer and globalid for known vulnerabilities ([#54](https://github.com/Nitish313/bidding_website/pull/54)).
- User-uploaded files are no longer tracked in git ([#45](https://github.com/Nitish313/bidding_website/pull/45)).

### Removed

- Unused `notifications` gem and the kaminari gems it pulled in ([#53](https://github.com/Nitish313/bidding_website/pull/53)).
- Empty `package.json` and Yarn wiring ([#50](https://github.com/Nitish313/bidding_website/pull/50)).
- Commented-out and unused code ([#48](https://github.com/Nitish313/bidding_website/pull/48), [#56](https://github.com/Nitish313/bidding_website/pull/56)).

[Unreleased]: https://github.com/Nitish313/bidding_website/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Nitish313/bidding_website/releases/tag/v1.0.0

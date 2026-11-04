# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Error reporting with Sentry (`sentry-ruby`, `sentry-rails`) from production only, switched on by `SENTRY_DSN`. Reports include the user's id only; 404s and 400s are not reported.
- An end-to-end test of a gig's whole lifecycle: two users sign up and activate, then the gig is posted, found by search, bid on, awarded, discussed in messages and delivered, with the notifications checked at each step.

### Changed

- Request logging (one JSON line per request) is configured in `config/initializers/lograge.rb` and on in every environment except development, including tests.
- Forms that fail validation (signup, profile, gigs, login, password reset) now answer HTTP 422 Unprocessable Content instead of 200, as current Rails expects.
- Upgraded sass-rails 5 → 6, which compiles stylesheets with SassC (LibSass) instead of the end-of-life Ruby Sass. The 422 responses use the current status name `:unprocessable_content`.
- Messaging now runs on the app's own `Conversation`, `ConversationParticipant` and `Message` models instead of the unmaintained mailboxer gem. Existing conversations, messages, read and trash state, and notifications were copied over with their ids, and the unread count is a single query ([#89](https://github.com/Nitish313/bidding_website/pull/89), [#90](https://github.com/Nitish313/bidding_website/pull/90), [#91](https://github.com/Nitish313/bidding_website/pull/91)).

### Fixed

- Replying to a conversation marks it as read for the person replying, so their own inbox no longer shows it as unread.
- A message from a since-deleted user now counts as unread, and messages from deleted users show as "Deleted user" ([#91](https://github.com/Nitish313/bidding_website/pull/91)).

### Security

- Rails 8.1.4 → 8.1.4.1, the security release fixing 21 advisories, including arbitrary file read and write in Active Storage image analysis (critical), a Strong Parameters bypass and IP spoofing in `RemoteIp` (high), and several XSS issues in Action View helpers. The Gemfile now requires at least 8.1.4.1.
- Patch updates for newly published advisories: rack 2.2.25 (multipart denial of service, `Rack::Static` header bypass), nokogiri 1.19.7, loofah 2.25.3, rails-html-sanitizer 1.7.2 and crass 1.0.8 (sanitizer bypasses and XSS), and addressable 2.9.2 (regular-expression denial of service).
- Gig and solution attachments only accept document, archive and image types (no HTML or SVG, which would run as pages on this site) and are limited to 20 MB. Profile pictures must be real images, not other files renamed to `.png`.

### Removed

- The mailboxer gem, its initializer and its database tables.
- CoffeeScript: the six empty `.coffee` stubs and the `coffee-rails` gem. All front-end code is plain JavaScript.

## [1.1.0] - 2026-10-17

Brings the app from Rails 5.2 and Ruby 2.7 to Rails 8.1 and Ruby 3.3, running on the
Rails 8.1 framework defaults, with no known gem vulnerabilities.

### Changed

- Upgraded Rails 5.2 → 6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → 8.1, one version at a time, each followed by its own switch to that version's framework defaults ([#60](https://github.com/Nitish313/bidding_website/pull/60), [#62](https://github.com/Nitish313/bidding_website/pull/62), [#63](https://github.com/Nitish313/bidding_website/pull/63), [#64](https://github.com/Nitish313/bidding_website/pull/64), [#65](https://github.com/Nitish313/bidding_website/pull/65), [#66](https://github.com/Nitish313/bidding_website/pull/66), [#69](https://github.com/Nitish313/bidding_website/pull/69), [#71](https://github.com/Nitish313/bidding_website/pull/71), [#73](https://github.com/Nitish313/bidding_website/pull/73), [#75](https://github.com/Nitish313/bidding_website/pull/75), [#76](https://github.com/Nitish313/bidding_website/pull/76), [#77](https://github.com/Nitish313/bidding_website/pull/77), [#79](https://github.com/Nitish313/bidding_website/pull/79), [#84](https://github.com/Nitish313/bidding_website/pull/84)).
- Switched to the Zeitwerk autoloader ([#61](https://github.com/Nitish313/bidding_website/pull/61)).
- Upgraded Ruby 2.7 → 3.3 on a supported Debian (bookworm) base image with Bundler 2.5 ([#67](https://github.com/Nitish313/bidding_website/pull/67)).
- Moving to the Rails 7.0 and 7.1 defaults rotates cookies to the new key derivation and format, so nobody is logged out ([#66](https://github.com/Nitish313/bidding_website/pull/66), [#71](https://github.com/Nitish313/bidding_website/pull/71)).
- Upgraded carrierwave 2.2 → 3.1, which no longer relies on `String#mb_chars` (removed in Rails 8.2); image resizing now goes through `image_processing` ([#80](https://github.com/Nitish313/bidding_website/pull/80)).
- Pinned the `mailboxer` gem to the tested GitHub commit ([#83](https://github.com/Nitish313/bidding_website/pull/83)).
- Upgraded RuboCop to 1.92 with rubocop-rails 2.38 and rubocop-minitest 0.41 ([#85](https://github.com/Nitish313/bidding_website/pull/85)).

### Added

- CI `audit` job checking every gem against the Ruby Advisory Database on each pull request and weekly ([#74](https://github.com/Nitish313/bidding_website/pull/74)).
- CI step that checks the 96% coverage minimum on its own; coverage settings live in `.simplecov` ([#81](https://github.com/Nitish313/bidding_website/pull/81)).
- CI steps that boot development mode and precompile production assets ([#86](https://github.com/Nitish313/bidding_website/pull/86)).

### Fixed

- Malformed or missing form fields (for example a plain string where a set of fields is expected) return 400 instead of crashing with a 500 ([#78](https://github.com/Nitish313/bidding_website/pull/78)).
- A conversation could be sent to a list of receivers, including yourself, before crashing; exactly one receiver is now required ([#87](https://github.com/Nitish313/bidding_website/pull/87)).
- A gig's skill list is limited to 20 skills and 1,000 characters; oversized lists crashed the save ([#82](https://github.com/Nitish313/bidding_website/pull/82)).
- Development mode failed to boot (`cannot load such file -- rexml/document`) because letter_opener_web 1.4 relied on `rexml` without declaring it; upgraded to letter_opener_web 3.0 ([#86](https://github.com/Nitish313/bidding_website/pull/86)).
- Production asset precompilation failed because Uglifier could not minify modern JavaScript; JavaScript is now minified with Terser and the unused Active Storage script is no longer loaded ([#76](https://github.com/Nitish313/bidding_website/pull/76)).

### Security

- Cleared every known gem vulnerability reported by bundler-audit, including Rails, Puma (now 7.2), carrierwave and jquery-rails, and removed unused browser-test gems ([#72](https://github.com/Nitish313/bidding_website/pull/72), [#73](https://github.com/Nitish313/bidding_website/pull/73)).
- Cookies are sent with `SameSite=Lax`, CSRF tokens are URL-safe, redirects never leave the site, and slow regular expressions time out after one second ([#64](https://github.com/Nitish313/bidding_website/pull/64), [#66](https://github.com/Nitish313/bidding_website/pull/66), [#77](https://github.com/Nitish313/bidding_website/pull/77)).

### Removed

- Spring, the unused `faker`, `chromedriver-helper`, `capybara` and `selenium-webdriver` gems, and the end-of-life `archive.debian.org` package source ([#65](https://github.com/Nitish313/bidding_website/pull/65), [#67](https://github.com/Nitish313/bidding_website/pull/67), [#72](https://github.com/Nitish313/bidding_website/pull/72)).

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

[Unreleased]: https://github.com/Nitish313/bidding_website/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Nitish313/bidding_website/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Nitish313/bidding_website/releases/tag/v1.0.0

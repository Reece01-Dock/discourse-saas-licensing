# Repository Guidelines

## Project Structure & Module Organization
- Backend code lives under `app/` (Ruby): models (`app/models/discourse_saas`), controllers, serializers, and jobs.
- Admin UI lives under `assets/javascripts/admin/` (Ember) with supporting styles in `assets/stylesheets/saas-licensing.scss`.
- Plugin config and locales sit in `config/` (`settings.yml`, `locales/`).
- Database migrations are in `db/migrate/` (ActiveRecord).
- Root entrypoint and route wiring: `plugin.rb`. Docs: `README.md`.

## Build, Test, and Development Commands
- Install gems: `bundle install` inside your Discourse dev container/environment.
- Run migrations (from Discourse root): `bundle exec rake db:migrate` (applies plugin migrations too).
- JS build/lint (if modified): `pnpm lint` or `yarn lint` if available in your environment; Ember assets are picked up by Discourse’s asset pipeline.
- Reload plugin in dev: restart `rails s` or touch `tmp/restart.txt` in a serverized setup.

## Coding Style & Naming Conventions
- Ruby: follow Discourse conventions, 2-space indent, frozen string literals, service/module namespace `DiscourseSaas`. Use PORO models with `self.table_name` set.
- JS/Ember: ES classes, tracked state, `@action` decorators; templates in `.hbs`. Prefer `ajax` helper and `popupAjaxError/notifySuccess` patterns.
- Styles: SCSS, prefer existing variables (e.g., `var(--primary-low)`), keep admin styling minimal.
- Files and routes use kebab-case for admin plugin paths (`admin-plugins-saas-licensing`).

## Testing Guidelines
- No dedicated test suite is included; rely on Discourse core test harness if adding specs.
- If adding tests, mirror Discourse patterns: request specs under `spec/requests/`, model specs under `spec/models/`, Ember tests under `test/javascripts/`.
- Keep fixtures minimal; prefer factory usage from Discourse core if available.

## Commit & Pull Request Guidelines
- Commits: concise imperative messages (e.g., "Add org seat management"), group related changes.
- PRs: describe the change, rationale, and deployment considerations (migrations, settings). Include screenshots/GIFs for UI changes (admin pages) and note any new settings or endpoints.

## Security & Configuration Tips
- Licensing can be toggled via `license_enabled` (site setting). Admin-only settings API lives at `/saas/admin/license/settings`.
- Payment is BYO; external systems should call `DiscourseSaas::Purchase.create_with_package` after successful charges. Do not store secrets here; integrate payment keys in your payment plugin.

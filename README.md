# Discourse SaaS Licensing Plugin

Production-ready SaaS licensing for Discourse. Supports individual and organisation licenses, Stripe Checkout, seat management, and loader-friendly validation endpoints. Built with Discourse’s plugin architecture (Ruby on Rails, ActiveRecord, Ember.js).

## Features
- License packages: name, price, duration days, seats, group mapping, org/individual flag.
- Stripe Checkout webhook: creates purchases, assigns Discourse groups, builds org groups for team licenses.
- Organisation management: owners invite/remove users, seat tracking (used vs total).
- Daily expiry job: revokes groups, marks licenses inactive, deactivates expired orgs.
- JSON APIs: user/org license status, admin CRUD for packages and org members, loader validation endpoints.
- Admin UI (Ember): manage packages, view orgs, invite/remove members, toggle settings.

## Installation
1) Add the plugin repository to your Discourse `plugins` folder (or as a git submodule).
2) Run migrations:
```bash
bundle exec rake db:migrate
```
3) Configure settings in the admin panel under Plugins → SaaS Licensing:
- `license_enabled`
- `stripe_public_key`
- `stripe_secret_key`
- `stripe_webhook_secret` (optional but recommended for signature verification)
- You can also edit these directly on the SaaS Licensing plugin page via the Settings section.

## Data Model
- `DiscourseSaas::LicensePackage`: name, price_cents, duration_days, seats, group_id, is_org_license.
- `DiscourseSaas::Purchase`: user_id, license_package_id, stripe_session_id, expires_at, organisation_id?, active.
- `DiscourseSaas::Organisation`: name, owner_id, group_id, seats_total, seats_used, active.
- `DiscourseSaas::OrganisationMember`: organisation_id, user_id, added_by_id.

## Stripe Checkout Webhook
Endpoint: `POST /saas/stripe/webhook`

Expected metadata on the Checkout Session:
```json
{
  "license_package_id": "<id of LicensePackage>",
  "user_id": "<discourse user id>",
  "organisation_name": "<optional org display name>"
}
```

Flow on `checkout.session.completed`:
1) Create `Purchase` with `expires_at` from `duration_days`, `active: true`.
2) Assign package group to the buyer.
3) If `is_org_license`:
   - Create a dedicated group `org_<slug>_<user>_<token>`.
   - Create `Organisation` with `seats_total` from the package.
   - Add buyer as owner + first member, consuming 1 seat.

## Expiry Logic
- `Jobs::DiscourseSaasLicenseExpiryJob` runs daily:
  - Finds active purchases with `expires_at <= now`.
  - Revokes package group from buyer.
  - Deactivates orgs and removes org memberships.
  - Marks purchases inactive.

## API Endpoints
All endpoints are mounted under `/saas`.

Public:
- `GET /saas/license/user/:id` → active licenses + groups for a user.
- `GET /saas/license/org/:id` → organisation detail, seats, members.

Admin (requires staff):
- `GET /saas/admin/license/packages`
- `POST /saas/admin/license/packages`
- `PUT /saas/admin/license/packages/:id`
- `DELETE /saas/admin/license/packages/:id`
- `GET /saas/admin/license/orgs`
- `GET /saas/admin/license/orgs/:id`
- `POST /saas/admin/license/orgs/:id/invite` (params: `username_or_email`)
- `DELETE /saas/admin/license/orgs/:id/member/:user_id`

### Example Responses
`GET /saas/license/user/42`
```json
{
  "user": {
    "id": 42,
    "username": "alice",
    "name": "Alice Example"
  },
  "licenses": [
    {
      "id": 5,
      "expires_at": "2024-01-05T00:00:00Z",
      "active": true,
      "organisation_id": null,
      "license_package_id": 2,
      "user_id": 42,
      "package": {
        "id": 2,
        "name": "Pro Individual",
        "price_cents": 2000,
        "duration_days": 30,
        "seats": 1,
        "group_id": 55,
        "is_org_license": false,
        "created_at": "2023-12-06T12:00:00Z",
        "updated_at": "2023-12-06T12:00:00Z"
      }
    }
  ],
  "groups": [
    { "id": 55, "name": "pro_individual" }
  ]
}
```

`GET /saas/license/org/7`
```json
{
  "organisation": {
    "id": 7,
    "name": "Acme Team",
    "owner_id": 42,
    "group_id": 77,
    "seats_total": 10,
    "seats_used": 3,
    "active": true,
    "created_at": "2023-12-06T12:00:00Z",
    "updated_at": "2023-12-06T12:00:00Z",
    "members": [
      { "id": 1, "organisation_id": 7, "user_id": 42, "username": "alice", "added_by_id": 42, "created_at": "2023-12-06T12:00:00Z" },
      { "id": 2, "organisation_id": 7, "user_id": 43, "username": "bob", "added_by_id": 42, "created_at": "2023-12-06T12:01:00Z" }
    ]
  }
}
```

## Loader Integration
- Use `/saas/license/user/:id` to validate a user’s active licenses.
- Use `/saas/license/org/:id` to validate an organisation and seats.
- Discourse groups are the source of truth; downstream loaders can enforce permissions using the returned group ids/names.

## Organisation Flow (example)
1) Admin creates an org package (e.g., seats=10, duration=365, group maps to `pro_org`).
2) Buyer completes Stripe Checkout with metadata `license_package_id`, `user_id`, `organisation_name`.
3) Webhook creates purchase, org `group` (`org_acme_<token>`), sets owner as first member.
4) Owner uses admin UI to invite users by username/email until seats are full.
5) Daily job revokes expired licenses and org access automatically.

## Admin UI
- Available at `/admin/plugins/saas-licensing`.
- Manage packages, view orgs, invite/remove members, refresh data.

## Safety & Notes
- Controllers guard with `license_enabled` and admin checks where needed.
- Stripe signing secret is optional but recommended.
- Group creation uses randomised slug to avoid collisions.

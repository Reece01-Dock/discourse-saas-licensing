# Discourse SaaS Licensing Plugin

Production-ready SaaS licensing for Discourse. Supports individual and organisation licenses, seat management, and loader-friendly validation endpoints. Built with Discourse’s plugin architecture (Ruby on Rails, ActiveRecord, Ember.js). Payment is intentionally decoupled—integrate your provider (e.g., Stripe) from another plugin or app by creating purchases/orgs via this plugin’s models/APIs.

## Features
- License packages: name, price, duration days, seats, group mapping, org/individual flag.
- Payment-agnostic: external plugins or services create purchases and trigger access; this plugin focuses on licensing + group management.
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
- You can also edit this directly on the SaaS Licensing plugin page via the Settings section.

## Data Model
- `DiscourseSaas::LicensePackage`: name, price_cents, duration_days, seats, group_id, is_org_license.
- `DiscourseSaas::Purchase`: user_id, license_package_id, stripe_session_id, expires_at, organisation_id?, active.
- `DiscourseSaas::Organisation`: name, owner_id, group_id, seats_total, seats_used, active.
- `DiscourseSaas::OrganisationMember`: organisation_id, user_id, added_by_id.

## Payment Integration (bring your own)
Implement payment in a companion plugin or external service:
1) Charge the buyer.
2) On success, call `DiscourseSaas::Purchase.create_with_package(user:, license_package:, organisation_name: nil)` (sets `expires_at` from package, grants group, and creates org/group for org packages).
3) Alternatively, create a `Purchase` manually, set `expires_at`, call `purchase.grant_access!`, and for org packages call `purchase.create_org!`.

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
2) Payment plugin/app charges buyer, creates purchase, and (for org packages) creates org + group.
3) Owner uses admin UI to invite users by username/email until seats are full.
4) Daily job revokes expired licenses and org access automatically.

## Admin UI
- Available at `/admin/plugins/saas-licensing`.
- Manage packages, view orgs, invite/remove members, refresh data.

## Safety & Notes
- Controllers guard with `license_enabled` and admin checks where needed.
- Group creation uses randomised slug to avoid collisions.

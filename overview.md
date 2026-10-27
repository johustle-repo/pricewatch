# PriceWatch System Overview

PriceWatch is a Flutter app for monitoring commodity prices in Lingayen. It runs as an Android APK and as a web app on Firebase Hosting. Shared data lives in Cloud Firestore, and Firebase Authentication handles identity. This document covers how the system is built. For the feature list, setup and build steps, see `README.md`.

## Architecture at a glance

```text
┌──────────────────────── Flutter client (Android / Web) ────────────────────────┐
│                                                                                 │
│  Screens (features/*/presentation/screens)                                      │
│        │  watch / call                                                          │
│  Controllers (ChangeNotifier, provided via Provider)                            │
│        │                                                                        │
│  Repositories (features/*/data)  ── one per feature                             │
│        │                                                                        │
│  CloudDataService (core/database) ── thin Firestore wrapper + session id        │
│        │                         DatabaseService ── legacy SQLite (local only)  │
└────────┼────────────────────────────────────────────────────────────────────────┘
         │
         ▼
  Firebase Authentication ── email/password identity (uid)
  Cloud Firestore          ── all shared data, guarded by firestore.rules
  Identity Toolkit REST    ── admin creates vendor accounts without signing out
  Cloud Functions (v2)     ── functions/index.js (managed-user + legacy migration)
  Firebase Hosting         ── serves build/web with SPA rewrite to index.html
```

## Startup sequence

`lib/main.dart`:

1. `Firebase.initializeApp` using `lib/firebase_options.dart` (project `pricewatch-apk`).
2. `AppDependencies.bootstrap()` (`lib/core/di/app_dependencies.dart`) opens the local SQLite database, loads `SharedPreferences`, creates one `CloudDataService`, and builds every repository around it. The client no longer seeds Firestore.
3. `AuthController.initialize()` restores the Firebase Auth session.
4. `ThemeController.load()` restores the light/dark preference.
5. `runApp(PriceWatchApp)`. If any step throws, a `_StartupFailureApp` error screen is shown instead.

## Layers

| Layer | Location | Responsibility |
| --- | --- | --- |
| Models | `lib/shared/models` | Plain Dart classes with `fromMap`/`toMap` (commodity, store, price entry, report, incident, user, watchlist, notification, session…). |
| Data service | `lib/core/database/cloud_data_service.dart` | Generic Firestore reads, streams and writes, `whereIn` batching (30-value limit, falls back to the full collection), ID generation, active-user/role checks, audit logs, cascading store deletes. |
| Repositories | `lib/features/*/data` | Feature-specific queries and business rules: auth, home, commodities, stores, market display, watchlist, reports, vendor incidents, notifications, profile, admin. |
| Controllers | `lib/features/*/presentation/controllers` | `ChangeNotifier` state for screens: loading/error states and user actions. |
| Screens & widgets | `lib/features/*/presentation`, `lib/shared/widgets` | Responsive Material UI. Shared components handle stats, badges, search, empty/loading states and price-trend indicators. |
| Pure logic | `lib/core/utils` | Current-price calculation (`market_prices.dart`), price-increase detection (`price_increases.dart`), QR encoding (`store_qr_codec.dart`), validators and formatters. These are unit tested. |

## Navigation and access control

`lib/core/router/app_router.dart` uses GoRouter with `refreshListenable: authController`, so the router re-runs its redirect whenever the auth state changes.

- **Public, no sign-in:** `/` (landing page) and `/display/lingayen-market`.
- **While auth initializes:** the app shows `/splash`.
- **Signed out:** protected routes redirect to `/login?from=<route>`, and the user returns to that route after signing in.
- **After sign-in:** admins go to `/admin` on the web or on screens at least as wide as the admin breakpoint. Community users go to `/home`. Vendors and admins on mobile go to `/modules`.
- **Admin routes** (`/admin/*`) redirect users who aren't admins to `/profile`.

Route guards only control navigation. The real enforcement is in Firestore security rules (below).

## Roles and identity model

Each signed-in account is linked through two documents:

- `access_control/{authUid}`: the authorization record, with `role` (`user` | `vendor` | `admin`), `user_id`, `store_id` (vendors only) and `active`.
- `users/{userId}`: the profile (name, email, role, store, `auth_uid`).

How accounts get created:

- **Community users** register in the app. The client writes both documents in one batch with role `user`.
- **Vendors** are created by an admin. `AdminRepository` calls the Identity Toolkit `accounts:signUp` REST endpoint, so the admin's own session stays signed in. It then writes the profile and access records and links the vendor to a store.
- **Legacy profiles** (from the old SQLite/seed data) are claimed on first Firebase sign-in when the email matches. The `password_hash` field is removed at that point. `functions/index.js` also provides `migrateLegacyUser`, `saveManagedUser` and `deleteManagedUser` callables that use the Admin SDK.
- **Deactivation** sets `access_control.active = false`. The rules treat an inactive account as having no role.

## Data model (Firestore collections)

All entity documents use a numeric ID stored both as the document ID and as an `id` field. IDs come from `generateId()` (`DateTime.now().microsecondsSinceEpoch`).

| Collection | Contents | Who can write (per `firestore.rules`) |
| --- | --- | --- |
| `categories`, `subcategories` | Commodity grouping | Admin (public read) |
| `commodities` | Name, category, unit, description, SRP | Admin (public read) |
| `stores` | Shop/market, location, owner | Admin (public read) |
| `price_entries` | `commodity_id`, `store_id`, `price`, `recorded_at`, source | Admin, or the vendor for their own `store_id`. Price must be > 0 and < 1,000,000. Public read. |
| `users` | Profiles | Admin. Users can edit only their own `full_name`/`email`, or deactivate themselves. |
| `access_control` | Role/authorization per auth UID | Admin. Self-creation is allowed only if it matches the user's own profile. |
| `watchlists` | User, commodity, price threshold | Owner |
| `notifications` | In-app messages, `is_read` | Admin or owner. Vendors can create `report_status_update` notifications. |
| `reports` | Community price complaints with an SRP snapshot and status | Created by the owner with status `pending`. Updated by admins, or by the store's vendor (status only). |
| `vendor_incidents` | Vendor concerns with 1–3 evidence photos | Created by the owner (validated lengths). Reviewed by admins. |
| `audit_logs`, `deletions` | Admin activity and deletion tombstones | Admin only |
| anything else | — | Denied |

## Core domain logic

- **Current market price** (`core/utils/market_prices.dart`): for each commodity, take each store's latest entry. A store counts only if its latest entry is within **30 days** of the commodity's newest record. From those entries the app computes average, lowest and highest prices, plus each store's previous price for trend arrows. A commodity whose newest price is older than **14 days** is marked stale.
- **SRP comparison:** prices above a commodity's SRP are flagged in the vendor, admin and analytics views. A flag is a signal to review the price, not a finding that a rule was broken.
- **Price-increase history** (`core/utils/price_increases.dart`): compares consecutive dated entries for the same commodity and store and lists the increases, newest first. Invalid dates and entries with the same timestamp are skipped.
- **Reporting flow:** the community user scans the store QR code (`store_qr_codec.dart` + `mobile_scanner`), picks a commodity and submits a report. The report is stored as `pending` with an SRP snapshot. When the admin or the store's vendor changes the status, the reporter gets a notification.
- **Watchlist alerts:** watched commodities are checked against the user's thresholds, and the app creates in-app notifications.
- **Public board** (`features/display`): checks for new data every 30 seconds and shows 12 products per page in a 3×4 grid. Pages rotate, and card height adjusts to the screen (see `public_board_algorithm_explanation.txt`).

## Admin tooling

- CRUD screens for categories, commodities, users/vendors, stores (archive and restore), prices, reports and incidents. Supported operations write `audit_logs` entries.
- **CSV import** (`csv_import_service.dart`): normalizes headers and field aliases, shows a preview, offers skip/update/replace for duplicates, and produces a downloadable error report. Sample files are in `samples/`.
- **Exports** (`admin_export_service.dart`, `report_export_service.dart`): PDF (`pdf`), Excel (`excel`) and CSV, built from the currently filtered rows.
- **Analytics** (`fl_chart`): SRP compliance, trends by day/week/month/year, category comparisons, the stores with the most reports, and report status distribution.

## Local storage

- `SharedPreferences` stores the active session user ID and the theme mode.
- `DatabaseService` is a legacy SQLite store (`sqflite`, with FFI versions for desktop and web). It is still initialized at startup, but feature repositories read from Firestore. Treat the app as online-first, not as a standalone offline system.

## Deployment

| Target | Command / output |
| --- | --- |
| Android | `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk` |
| Web | `flutter build web --release` → `build/web`, then `firebase deploy --only hosting` |
| Security rules | `firebase deploy --only firestore:rules` |
| Cloud Functions | Source is in `functions/` (Node 20), but `firebase.json` has no `functions` entry yet, so add one before deploying |

## Supporting folders

| Path | Purpose |
| --- | --- |
| `functions/` | Callable Cloud Functions (Admin SDK) |
| `tool/` | Node scripts for data maintenance (`add_survey_commodities.js`, `populate_price_history.js`) |
| `scripts/run_web_wasm.ps1` | Runs the web app with Wasm/Skwasm to avoid WebGL context limits |
| `samples/` | Example store and price CSVs for import |
| `test/` | Unit tests (CSV import, market prices, price increases, report export, subcategory summaries, theme) and vendor widget/layout tests |

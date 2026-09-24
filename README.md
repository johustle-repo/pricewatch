# PriceWatch

PriceWatch is a Flutter application for monitoring commodity prices and reporting market concerns in Lingayen. It includes a public market display, community tools, a vendor workspace, and an administrator workspace, with shared data stored in Firebase.

## System scope

The system focuses on agricultural and wet-market commodities such as rice, fish, meat, and vegetables. Prices are associated with a commodity, its unit, a store, a source, and a recorded date. Suggested Retail Price (SRP) comparisons help users identify prices that need review.

Services and differentiated finished products are outside the current market-price monitoring scope. A price increase or an above-SRP indicator is a monitoring signal, not an automatic determination of a violation.

## Roles and access

| Role | Main capabilities |
| --- | --- |
| Public visitor | View the Lingayen market price display without signing in. |
| Community user | Browse commodities and stores, compare prices, maintain a watchlist, submit reports and incidents, receive in-app notifications, and manage a profile. |
| Vendor | Manage products and selling prices for an assigned shop, view shop reports, monitor pricing concerns, and access the shop QR code. |
| Administrator | Manage categories, commodities, stores, vendor accounts, prices, reports, incidents, and analytics. |

Community users register through the application. Vendor accounts are created by administrators after shop verification and linked to a shop. Administrative access is controlled through account roles and Firebase access records.

## Features

### Public market display

- Public landing page and dedicated Lingayen market display at `/display/lingayen-market`.
- Market commodity prices, commodity visuals, price trends, and SRP indicators.
- Responsive layouts for different screen sizes.
- Automatic refresh checks every 30 seconds, manual refresh, and loading/error states.
- Entry points to the authenticated application.

### Account registration and authentication

- Community registration with full name, email, password, and password confirmation.
- Password validation requiring at least eight characters, one uppercase letter, and one number.
- Email/password sign-in through Firebase Authentication.
- Restoration of the authenticated account on startup and logout.
- Role-aware navigation and restricted administrator routes.
- Administrator-managed vendor access and shop assignment.
- Profile viewing, profile editing, and password changes.

To create a community account, open **Create account** from the login page, enter the required details, confirm the password, and submit the form. Vendors receive their account from an administrator.

### Community dashboard and commodity browsing

- Home dashboard with commodity categories, featured products, recent price updates, and summary counts.
- Category browsing and commodity search/filtering.
- Commodity details with category, unit, description, and SRP.
- Average, lowest, and highest available store prices.
- Store-level price comparisons with recorded dates.
- Price-history charts based on recorded commodity data.
- Quick access to watchlisting and price reporting.

### Dated price-increase warnings

- A **Recorded price increases** panel on the commodity detail screen.
- Warning icons for increases between consecutive dated records for the same commodity and store.
- Store name, previous price and date, new price and date, increase amount, and percentage increase where calculable.
- Newest increases displayed first.
- An explanatory state when available records contain no increases.
- Invalid dates are excluded; records at the same instant do not establish a chronological increase.

The date shown is the date the price was recorded. It does not establish the exact moment a vendor changed the selling price. Percentage increases require a positive previous price.

### Markets and stores

- Searchable store directory with market/location information.
- Store details and listed commodity prices.
- Directory summaries including ratings, report counts, and price-update counts.
- Shop QR codes that identify the store for the reporting workflow.
- Vendor document legend with both labels and colors:

| Color | Document type |
| --- | --- |
| Red | Business Permit |
| Green | Ticket |

The legend appears in the store directory, administrator user management, and vendor dashboard. It identifies document types; the current store records do not track uploaded permits, tickets, or document verification status.

### Watchlist and notifications

- Add or remove commodities from a personal watchlist.
- Set and update price thresholds.
- Review watched-item prices and threshold-related alerts.
- In-app notification list and unread counts.
- Mark notifications read/unread, mark all read, and delete notifications.
- Notifications for report submission/status changes and watchlist threshold conditions.

### Price reports

- Scan a shop QR code to start a report for the identified store.
- Select a commodity and submit an observed price, reason, and optional photo-path/reference.
- Store an SRP snapshot with the report for later comparison.
- View report details, submission/update dates, and review status.
- Search reports and filter by status.
- Select a specific submission date through a calendar picker, or clear the date to show all dates.
- Calendar filtering in community reports, vendor shop reports, and administrator report management.
- Administrator review and status updates, with notifications to the reporter.
- Export administrator reports as PDF, Excel, or CSV; exports use the filtered result set.

The calendar filters the report submission date in local time. It is not a separate user-entered observation date. The price-report form currently accepts an optional photo reference; camera/gallery evidence capture is available in the separate incident-report workflow.

### Vendor incident reports

- Report a vendor concern using the vendor name, market location, reason, and details.
- Capture evidence photos using the camera or choose photos from the device.
- Submit and view incident records, evidence, and review status.
- Administrator incident review, status updates, and deletion controls.
- Separate incident records from commodity-price complaints.

### Vendor workspace

- Dashboard for the assigned shop with product, pending-report, stale-price, and above-SRP summaries.
- Add products from the commodity catalog to the shop's listings.
- Update selling prices and review product price history.
- Remove products from the shop's listings.
- Search, sort, and inspect product price records.
- Compare current prices with SRP and identify stale or missing price information.
- View buyer reports linked to the shop.
- View the shop QR code, download the QR image, and copy the store reference.
- Dedicated product and QR sections, with mobile and desktop layouts.
- Vendor document legend: red for Business Permit and green for Ticket.

### Administrator workspace

- Overview dashboard with operational counts, pricing concerns, report activity, and recent administrative activity.
- **Categories:** create, edit, and delete commodity categories, subject to record dependencies.
- **Commodities:** manage names, categories, units, descriptions, and SRP values.
- **Users:** search/filter accounts, create and manage vendor accounts, and assign shops.
- **Stores:** manage store/location/owner information, archive and restore stores, and access shop QR tools.
- **Prices:** manage price entries, inspect source and recorded dates, compare prices against SRP, and import/export records.
- **Reports:** search, status/date filtering, pagination, review, status changes, and PDF/Excel/CSV exports.
- **Incidents:** review vendor concerns and evidence, update status, and delete records.
- **Analytics:** inspect pricing, compliance, trends, report activity, and watchlist-related summaries.
- Administrative audit records for supported data-management operations.
- Dedicated web navigation and access to the public display.

### CSV import and document exports

CSV means **Comma-Separated Values**: a plain-text table with a header row and data rows. CSV files can be opened in spreadsheet applications such as Microsoft Excel.

- CSV import for store and price records.
- Header normalization and supported field aliases during import.
- Preview of detected rows before importing.
- Duplicate-handling options: skip, update, or replace matching data.
- Import result counts and downloadable CSV error reports.
- Store-directory and price-register exports in PDF and Excel formats.
- Report exports in PDF, Excel (`.xlsx`), and CSV formats.
- Analytics exports in PDF and Excel formats.

### Analytics

- Commodity compliance monitoring against SRP.
- Above-SRP counts, compliance summaries, stale-price indicators, and pending-report summaries.
- Commodity price trends with day, week, month, and year intervals.
- Category price-versus-SRP comparisons, top reported stores, market activity by location, and report-status distribution charts.
- Refresh controls and PDF/Excel export.

### In-app guide

An expandable **PriceWatch guide** explains account creation, CSV files, commodities versus non-commodities within the project scope, and the application's programming languages.

| Screen | Guide location |
| --- | --- |
| Create Account | Above the full-name field in the registration form. |
| Profile | At the top of the page. |
| Commodities | At the top of the commodity list. |
| Admin: Manage Prices | Above the page header when the price-management content is available. |
| Admin: Manage Stores | At the top of the page. |

### Shared interface features

- Responsive mobile and desktop layouts.
- Light/dark theme definitions and theme-aware components.
- Loading indicators, skeleton placeholders, empty states, and retry/error messages.
- Reusable search, status, warning, notification, and commodity-visual components.
- Philippine peso formatting and local date/time labels.

## Technology stack

| Area | Technology |
| --- | --- |
| Application language | Dart, with SDK constraint `^3.10.8` |
| UI framework | Flutter |
| Server-side functions | JavaScript with Firebase Cloud Functions; Node.js 20 in `functions/package.json` |
| Authentication | Firebase Authentication |
| Shared application data | Cloud Firestore |
| State management | Provider |
| Navigation | GoRouter |
| Local infrastructure | SQLite (`sqflite` and platform variants), SharedPreferences |
| Charts | `fl_chart` |
| QR generation/scanning | `qr_flutter`, `mobile_scanner` |
| Incident evidence | `camera`, `image_picker` |
| Import/export | `csv`, `excel`, `pdf`, `file_picker`, `file_saver` |
| Web hosting configuration | Firebase Hosting |

Feature repositories currently use Firestore. Local database and legacy seed/migration infrastructure also exist, but the application should not be treated as a fully standalone offline system. Client startup does not automatically seed Firestore.

## Project structure

```text
lib/
  core/                 Configuration, database services, routing, theme, utilities
  features/
    admin/              Administration, analytics, imports and exports
    auth/               Registration, login and authentication
    commodities/        Categories, catalog and commodity details
    display/            Public Lingayen market display
    home/               Community dashboard
    navigation/         Shared application navigation
    notifications/      In-app notifications
    profile/            Account profile and password management
    reports/            Price reports, QR scanning and vendor incidents
    stores/             Store directory and store details
    user/               Role-aware module entry screen
    vendor/             Vendor dashboard, products and shop QR
    watchlist/          Watched commodities and price thresholds
  shared/               Shared models and UI widgets
functions/              Firebase callable functions for managed accounts/migration
scripts/                Web development helper
test/                   Unit and widget tests
```

## Setup and run

Use a Flutter installation that provides Dart compatible with `^3.10.8`. Android development also requires the Android SDK and an emulator or connected device; web development can use Chrome.

The repository includes Firebase configuration in `lib/firebase_options.dart`, `android/app/google-services.json`, and `firebase.json`. Use the intended Firebase project with Email/Password authentication, Firestore data, account access records, and security rules configured. Managed-account operations also use the callable functions in `functions/index.js`.

```bash
flutter pub get
flutter run
```

Run the web application:

```bash
flutter run -d chrome
```

If Chrome reports `Too many active WebGL contexts` or CanvasKit `_handledContextLostEvent` errors after several hot restarts, close the old browser tab and use the included WebAssembly/Skwasm helper:

```powershell
.\scripts\run_web_wasm.ps1 49543
```

The port argument is optional.

### Build artifacts

```bash
flutter build apk --release
flutter build web --release
```

The Android APK is generated at `build/app/outputs/flutter-apk/app-release.apk`. Web output is generated in `build/web`. Source changes become available to users only after installing a new build or deploying the updated web output.

### Firebase deployment

The current `firebase.json` configures Firestore rules and Firebase Hosting with `build/web` as the hosting directory.

```powershell
firebase.cmd deploy --only firestore:rules
firebase.cmd deploy --only hosting
```

Build the web application before deploying Hosting. The repository contains Cloud Functions source, but its current `firebase.json` does not declare a functions deployment source; configure that before deploying those functions through this project configuration.

### Legacy demo accounts

These credentials are documented for the legacy demo dataset. Local seed records alone do not create Firebase Authentication accounts; sign-in requires corresponding Firebase Authentication and access/profile records.

| Role | Email | Legacy demo password |
| --- | --- | --- |
| Community user | `user@pricewatch.app` | `Password123` |
| Admin | `admin@pricewatch.app` | `Admin123` |
| Vendor | `vendor@pricewatch.app` | `Vendor123` |

Community users can register through the app. Vendor accounts are managed by administrators.

## Validation

```bash
flutter analyze
flutter test
```

The test suite covers CSV parsing, report export, price-increase comparisons, report-date matching, and selected application/vendor widget layouts.

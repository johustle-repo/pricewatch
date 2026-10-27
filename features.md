# PriceWatch: Background of the Study and System Features

## Background of the Study

Food prices strongly affect the cost of living of Filipino households. Rice, fish, meat, and vegetables take up a large share of the budget of an ordinary family, so even small price increases in local markets are felt immediately, especially by low-income consumers. In the Philippines, the Price Act (Republic Act No. 7581, as amended by Republic Act No. 10623) protects consumers from unreasonable price increases on basic necessities and prime commodities. Government agencies such as the Department of Agriculture (DA) and the Department of Trade and Industry (DTI) issue Suggested Retail Prices (SRPs) and conduct price monitoring to guide consumers and sellers.

In public and wet markets such as those in Lingayen, Pangasinan, price monitoring is still largely manual. Monitoring personnel visit stalls, record prices on paper or in spreadsheets, and consolidate the data later. This process is slow and labor-intensive, and the results seldom reach consumers while they are shopping. Buyers usually do not know the SRP of a commodity, cannot easily compare prices between stores, and have no simple, organized channel for reporting overpricing or other vendor concerns. Vendors also lack a convenient way to publish their selling prices and to see how their prices compare with the SRP.

These problems create an information gap between consumers, vendors, and the authorities who monitor prices. Without timely and accessible price data, consumers cannot make informed purchasing decisions, unreasonable price increases may go unnoticed, and complaints are difficult to record, track, and resolve.

Mobile and web technologies offer a practical way to close this gap. Smartphones are widely used, and cloud platforms make it possible to share data in real time between many users. A centralized system can collect prices from vendors and administrators, compare them automatically with SRPs, display them publicly, and let consumers submit reports that administrators can review.

**PriceWatch** was developed in response to these needs. It is a Flutter-based mobile (Android) and web application, backed by Firebase, for monitoring agricultural and wet-market commodity prices and reporting market concerns in Lingayen. It brings together four groups of users in one platform:

- **Public visitors**, who can view a market price display without signing in.
- **Community users (buyers)**, who can browse and compare prices, keep a watchlist, and submit price reports and vendor incident reports.
- **Vendors**, who manage the products and selling prices of their assigned shop and respond to reports about it.
- **Administrators**, who manage the commodity catalog, stores, prices, accounts, reports, incidents, and analytics.

### Objectives

The study aims to:

1. Provide consumers with accessible, up-to-date commodity prices, store-level comparisons, and SRP references.
2. Give vendors a simple tool for maintaining their shop's product listings and selling prices.
3. Provide a QR-based reporting workflow that ties price complaints to a specific store.
4. Support administrators with centralized data management, report and incident review, analytics, and exportable records.
5. Highlight above-SRP prices, stale price data, and recorded price increases as signals for further review.

### Scope and Limitations

- The system covers agricultural and wet-market commodities such as rice, fish, meat, and vegetables. Services and differentiated finished products are outside its scope.
- Each price is tied to a commodity, its unit, a store, a source, and the date it was recorded. The recorded date is not necessarily the exact moment a vendor changed the price.
- An above-SRP indicator or a recorded price increase is a **monitoring signal**, not an automatic finding of a violation. Final assessment remains with the administrators and the proper authorities.
- The application is online-first. Shared data is stored in Cloud Firestore, so an internet connection is required for most features.
- Vendor accounts are created only by administrators after shop verification.

### Significance of the Study

- **Consumers** can make informed purchasing decisions and report concerns easily.
- **Vendors** can present transparent prices and keep their listings accurate.
- **Market administrators and local government** gain organized price data, report tracking, and analytics that support monitoring and policy decisions.
- **Future researchers** can use the system as a reference for digital price monitoring and community reporting tools.

---

## System Features

### 1. Public Market Display

- Public landing page and a dedicated Lingayen market display (`/display/lingayen-market`) that requires no sign-in.
- Shows commodity prices, commodity images, price trends, and SRP indicators.
- Rotating board that shows 12 products per page in a 3-column by 4-row grid, moving to the next page automatically.
- Card heights adjust to the available screen height so the board fills the display without overflowing.
- Checks for new data every 30 seconds, with manual refresh and loading and error states.
- Links to sign in to the full application.

### 2. Account Registration and Authentication

- Community user registration with full name, email, password, and password confirmation.
- Password rules: at least eight characters, including one uppercase letter and one number.
- Email and password sign-in through Firebase Authentication.
- Restores the signed-in session at startup, and supports logout.
- Role-based navigation for community users, vendors, and administrators, with protected administrator routes.
- Firestore security rules that enforce role-based access to data.
- Vendor accounts created and assigned to a shop by an administrator.
- Profile viewing and editing, and password changes.

### 3. Community Dashboard and Commodity Browsing

- Home dashboard with commodity categories, featured products, recent price updates, and summary counts.
- Category browsing, commodity search, and filtering.
- Commodity details: category, unit, description, and SRP.
- Average, lowest, and highest current prices across stores.
- Store-by-store price comparison with recorded dates.
- Price history charts.
- Stale price indicators for commodities without recent price records.
- Quick actions to add a commodity to the watchlist or report a price.

### 4. Recorded Price Increase Warnings

- A **Recorded price increases** panel on the commodity detail screen.
- Detects increases between consecutive dated records of the same commodity at the same store.
- Shows the store, previous price and date, new price and date, the amount of increase, and the percentage increase where it can be calculated.
- Lists the newest increases first and shows an explanatory message when there are none.
- Skips records with invalid dates or identical timestamps.

### 5. Markets and Stores

- Searchable store directory with market and location information.
- Store details with listed commodity prices.
- Store summaries with ratings, report counts, and price update counts.
- A QR code for each shop that identifies the store in the reporting workflow.

### 6. Watchlist and Notifications

- Add commodities to, or remove them from, a personal watchlist.
- Set and update a price threshold for each watched commodity.
- Alerts when a watched commodity reaches its threshold.
- In-app notification list with unread counts.
- Mark notifications as read or unread, mark all as read, and delete notifications.
- Notifications when a report is submitted or its status changes.

### 7. Price Reports (QR-Based)

- Scan a shop's QR code to start a report for that store.
- Choose a commodity and submit the observed price, a reason, and an optional photo reference.
- Saves a snapshot of the SRP with each report for later comparison.
- View report details, submission and update dates, and review status.
- Search reports and filter them by status.
- Calendar date filter for submission dates, which can be cleared to show all dates. It is available to community users, vendors, and administrators.
- Administrators and the store's vendor can update a report's status, and the reporter is notified of the change.

### 8. Vendor Incident Reports

- Report a vendor concern with the vendor name, market location, reason, and details.
- Attach one to three evidence photos taken with the camera or chosen from the device gallery.
- View submitted incidents, their evidence, and their review status.
- Administrators review incidents, update their status, and delete them.
- Incident records are kept separate from commodity price reports.

### 9. Vendor Workspace

- Dashboard for the assigned shop showing products, pending reports, stale prices, and above-SRP items.
- Add products from the commodity catalog to the shop's listings.
- Update selling prices and view each product's price history.
- Remove products from the shop's listings.
- Search, sort, and inspect product price records.
- Compare current prices with the SRP and identify stale or missing prices.
- View buyer reports about the shop and update their status.
- View and download the shop's QR code, and copy the store reference.
- Layouts for both mobile and desktop.

### 10. Administrator Workspace

- **Dashboard:** operational counts, pricing concerns, report activity, and recent administrative activity.
- **Categories:** create, edit, and delete commodity categories. Categories that other records depend on are protected.
- **Commodities:** manage names, categories, units, descriptions, and SRP values.
- **Users:** search and filter accounts, create and manage vendor accounts, assign shops, and deactivate accounts.
- **Stores:** manage store, location, and owner information, archive and restore stores, and use shop QR tools.
- **Prices:** manage price entries, check sources and recorded dates, compare prices with SRP, and import or export records.
- **Reports:** search, filter by status and date, page through results, review reports, change their status, and export them.
- **Incidents:** review vendor concerns and evidence, update their status, and delete records.
- **Analytics:** pricing, compliance, trends, report activity, and watchlist summaries.
- Audit logs for supported data management operations.
- A dedicated web navigation layout and a link to the public display.

### 11. CSV Import and Document Export

- CSV import for store and price records.
- Normalizes column headers and accepts common field name aliases.
- Previews detected rows before importing.
- Handles duplicates by skipping, updating, or replacing matching records.
- Shows import result counts and offers a downloadable CSV error report.
- Exports the store directory and price register to PDF and Excel.
- Exports reports to PDF, Excel (`.xlsx`), and CSV, using the currently filtered results.
- Exports analytics to PDF and Excel.

### 12. Analytics

- SRP compliance monitoring per commodity.
- Counts of above-SRP prices, compliance summaries, stale price indicators, and pending report summaries.
- Commodity price trends by day, week, month, and year.
- Charts comparing category prices with SRP, the stores with the most reports, market activity by location, and report status distribution.
- Refresh controls and PDF and Excel export.

### 13. In-App Guide

- An expandable **PriceWatch guide** that explains how to create an account, what CSV files are, which items count as commodities in the project's scope, and which programming languages the application uses.
- Available on the Create Account, Profile, Commodities, Admin Manage Prices, and Admin Manage Stores screens.

### 14. Shared Interface Features

- Responsive layouts for mobile, tablet, and desktop.
- Light and dark themes, with the user's choice remembered.
- Loading indicators, skeleton placeholders, empty states, and retry and error messages.
- Reusable search, status badge, warning, notification, price trend, and commodity image components.
- Philippine peso (₱) formatting and local date and time labels.

### 15. Platform and Technology

| Area | Technology |
| --- | --- |
| Language and UI framework | Dart and Flutter (Android and web) |
| Authentication | Firebase Authentication (email and password) |
| Database | Cloud Firestore, protected by security rules |
| Server-side functions | Firebase Cloud Functions (JavaScript, Node.js 20) for managed accounts and legacy data migration |
| Hosting | Firebase Hosting for the web version |
| State management and navigation | Provider and GoRouter |
| Charts | `fl_chart` |
| QR codes | `qr_flutter` (generation) and `mobile_scanner` (scanning) |
| Evidence photos | `camera` and `image_picker` |
| Import and export | `csv`, `excel`, `pdf`, `file_picker`, and `file_saver` |
| Local storage | SharedPreferences for the session and theme, and SQLite (legacy) |

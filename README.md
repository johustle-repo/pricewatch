# PriceWatch

PriceWatch is a Flutter commodity price monitoring and reporting app for Lingayen market workflows.

## Run

```bash
flutter pub get
flutter run
```

For web:

```bash
flutter run -d chrome
```

If Chrome reports `Too many active WebGL contexts` or CanvasKit
`_handledContextLostEvent` errors after several hot restarts, close the old
browser tab and run the web app in WebAssembly/Skwasm mode:

```powershell
.\scripts\run_web_wasm.ps1 49543
```

The port argument is optional.

## Seeded Accounts

Use these accounts after the local database or Firestore seed data has been initialized.

| Role | Email | Password |
| --- | --- | --- |
| Community user | `user@pricewatch.app` | `Password123` |
| Admin | `admin@pricewatch.app` | `Admin123` |
| Vendor | `vendor@pricewatch.app` | `Vendor123` |

Vendor accounts are managed by administrators in the app. Community users can register from the register screen.

## Firestore Rules

Deploy the local Firestore rules with:

```bash
firebase.cmd deploy --only firestore:rules
```


CRAWLING FOR PRICING
Focus on Wet Market
Acceptability (Remove SUS TAM)
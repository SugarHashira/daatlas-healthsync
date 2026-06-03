<p align="center">
  <img src="https://raw.githubusercontent.com/SugarHashira/daatlas-healthsync/master/docs/icon.png" width="120" alt="daatlas-healthsync app icon" />
</p>

# daatlas-healthsync

**Sync your Nightscout diabetes data to Apple Health.**

A lightweight iOS app that bridges Nightscout and Apple Health — syncing glucose, insulin, and carbs into one unified timeline. No backend, no account, no third-party dependencies.

> **Looking for the full experience?** This is the focused standalone version. The complete **[daatlas](https://github.com/SugarHashira/daatlas)** project adds Oura Ring integration, Dexcom support, dashboard views, trends analysis, and more.

> iOS 16+ · SwiftUI · HealthKit · Swift Concurrency

---

## What it does

```
Tandem t:slim X2
      │
      ▼
t:connect  ──►  Nightscout  ──►  daatlas-healthsync  ──►  Apple Health
                                                          (unified timeline)
```

Fetches glucose readings, insulin deliveries, and carb entries from your Nightscout instance and writes them to Apple Health — available to every app in the ecosystem.

---

## Features

- **Glucose sync** — Blood glucose readings in mg/dL or mmol/L
- **Insulin tracking** — Bolus and basal deliveries mapped to HealthKit insulin types
- **Carb logging** — Dietary carbohydrate entries
- **Deduplication** — Never writes the same record twice (timestamp fuzzy-matching)
- **Background sync** — Configurable intervals (5 min – 2 hours) via `BGAppRefreshTask`
- **Sync logs** — Complete audit trail of what synced and when (last 100 entries)
- **Selective sync** — Enable or disable glucose, insulin, and carbs independently
- **Configurable lookback** — Fetch 7 days to 1 year of historical data

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Health data | HealthKit |
| Concurrency | Swift async/await · `actor` types throughout |
| Background | BGAppRefreshTask |
| Auth | SHA-1 via CryptoKit (Nightscout API secret) |
| Networking | URLSession |
| Persistence | UserDefaults |
| Build | XcodeGen (`project.yml`) |
| Dependencies | None |
| Min target | iOS 16.0 |

---

## Architecture

```
SwiftUI Views (ContentView, SettingsView, LogsView)
        │
        ▼
SyncViewModel (@MainActor)
        │
        ├── NightscoutService (actor)  ─► REST API client
        ├── SyncService       (actor)  ─► orchestration + deduplication
        └── HealthKitService  (actor)  ─► Apple Health read/write

UserSettings (actor) ─► UserDefaults wrapper
```

All services are `actor` types — compile-time thread safety, no manual locking. `HealthKitService` is the single write path to Apple Health.

---

## Build

Requires Xcode 15+ and a device or simulator running iOS 16+.

```bash
git clone https://github.com/SugarHashira/daatlas-healthsync.git
cd daatlas-healthsync

# (Optional) regenerate Xcode project from project.yml
brew install xcodegen
xcodegen generate

open DaatlasHealthSync.xcodeproj
# Cmd+B to build · Cmd+R to run
```

---

## Setup

### Nightscout

Ensure your Nightscout instance has REST API enabled:

```
API_SECRET=your_secret_here
ENABLE=api
```

### App configuration

1. Open the app → tap the gear icon → **Settings**
2. Enter your **Nightscout URL** (e.g. `https://your-nightscout.fly.dev`)
3. Enter your **API Secret**
4. Tap **Test Connection**
5. Tap **Request HealthKit Authorization**
6. Enable the data types you want synced
7. Tap **Sync Now** for a manual sync, or enable **Auto-sync** for background operation

### Nightscout hosting options

- **[Fly.io](https://fly.io)** — Docker-based, free tier available → [setup guide](https://nightscout.github.io/nightscout/fly/)
- **[Railway](https://railway.app)** — Simple deploy from GitHub
- **[Heroku](https://heroku.com)** — Classic option (paid plans only now)
- **Self-hosted** — Raspberry Pi or any server with Docker

---

## Data mapping

| Source | Data | Apple Health |
|--------|------|-------------|
| Nightscout | SGV entries | Blood Glucose |
| Nightscout | Bolus treatments | Insulin Delivery (Bolus) |
| Nightscout | Temp basal treatments | Insulin Delivery (Basal) |
| Nightscout | Carb treatments | Dietary Carbohydrates |

---

## Project structure

```
daatlas-healthsync/Sources/
├── App/
│   ├── DaatlasHealthSyncApp.swift   # @main entry, scene setup
│   └── AppDelegate.swift            # Background task registration & scheduling
├── Services/
│   ├── SyncService.swift            # Actor: orchestration + deduplication
│   ├── NightscoutService.swift      # Actor: Nightscout REST client
│   └── HealthKitService.swift       # Actor: HealthKit read/write
├── ViewModels/
│   └── SyncViewModel.swift          # @MainActor: all published state
├── Views/
│   └── ContentView.swift            # Main UI, settings, logs
└── Models/
    ├── GlucoseEntry.swift           # SGV with mg/dL ↔ mmol/L conversion
    ├── NightscoutTreatment.swift    # Insulin (bolus/basal), carbs
    ├── UserSettings.swift           # Actor-wrapped UserDefaults
    └── SyncLog.swift                # Sync operation audit trail
```

---

## Troubleshooting

**Connection failed** — Check your Nightscout URL and API secret. Verify the instance is online.

**HealthKit authorization denied** — Go to iOS Settings → Privacy & Security → Health → DaAtlas → enable write access for each data type.

**Data not appearing** — Confirm sync completed in Sync Logs. Check that write permissions were granted for that specific data type.

---

## Great apps in the diabetes space

- **[Gluroo](https://gluroo.com)** — a beautifully designed diabetes management app. If you want a polished all-in-one experience, check it out.
- **[Stash Diabetes](https://www.stashdiabetes.com)** — great app for managing and tracking diabetes supplies.
- **[xDrip4iOS](https://xdrip4ios.readthedocs.io)** — open-source CGM reader for iOS. The go-to for DIY CGM setups.

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.

---

## Disclaimer

daatlas-healthsync is not a medical device. It is a data utility for personal use. Always consult your healthcare provider for diabetes management decisions.

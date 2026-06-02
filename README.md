# daatlas-healthsync

**Sync your Nightscout diabetes data to Apple Health**

A simple iOS app that bridges your Nightscout instance and Apple Health, syncing glucose, insulin, and carbs into one place.

> **Looking for the full experience?** This is the lightweight standalone version. The complete **daatlas** project includes Oura Ring integration, dashboard views, trends analysis, and workout logging — check it out at [github.com/SugarHashira/daatlas](https://github.com/SugarHashira/daatlas).

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TANDEM t:slim X2                                  │
│                         (Insulin Pump + Control-IQ)                         │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            TANDEM MOBILE APP                                │
│                      (Remote bolusing & data upload)                        │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        t:connect WEB SERVICE                                │
│                   (Tandem's cloud - yourdata.t:connect.com)                 │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NIGHTSCOUT                                        │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │  Pulls data from t:connect                                      │     │
│    │  Provides REST API for apps to consume                          │     │
│    │  Web UI for glucose visualization                               │     │
│    └─────────────────────────────────────────────────────────────────┘     │
│                              Hosted on: Fly.io                              │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DAATLAS-HEALTHSYNC                                  │
│    ┌─────────────────────────────────────────────────────────────────┐     │
│    │  Fetches treatments (insulin, carbs) from Nightscout           │     │
│    │  Fetches glucose entries from Nightscout                       │     │
│    │  Syncs everything to Apple Health via HealthKit               │     │
│    └─────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            APPLE HEALTH                                     │
│     Glucose + Insulin + Carbs unified with Sleep, Activity, Heart Health   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. ✅ A Nightscout instance deployed and accessible
2. ✅ Your t:slim X2 data flowing into Nightscout
3. ✅ Nightscout REST API enabled (`API_SECRET` env var set)
4. ✅ iOS 16+ device
5. ✅ Apple Health app installed

## Setup

### 1. Configure Nightscout API

In your Nightscout environment variables:

```
API_SECRET=your_secret_here
ENABLE=api
```

### 2. Install the App

```bash
git clone https://github.com/SugarHashira/daatlas-healthsync.git
open DaatlasHealthSync.xcodeproj
# Build and run on your device (Cmd+R)
```

### 3. Configure the App

1. Open the app
2. Go to **Settings** (gear icon)
3. Enter your **Nightscout URL** (e.g., `https://your-nightscout.fly.dev`)
4. Enter your **API Secret**
5. Tap **Test Connection**
6. Tap **Request HealthKit Authorization**
7. Choose what to sync: Glucose, Insulin, Carbs

### 4. Sync

- Tap **Sync Now** for a manual sync
- Enable **Auto-sync** for automatic background syncs

## Features

- **Selective sync** — choose which data types to sync
- **Deduplication** — won't write the same data twice
- **Background sync** — configurable intervals (5 min to 2 hours)
- **Sync logs** — audit trail of what was synced and when
- **mg/dL and mmol/L** — both glucose units supported

## What Gets Synced

| Data Type | HealthKit Type |
|-----------|---------------|
| Glucose | Blood Glucose |
| Insulin (Bolus) | Insulin Delivery (Bolus) |
| Insulin (Basal) | Insulin Delivery (Basal) |
| Carbs | Dietary Carbohydrates |

## Tech Stack

- **SwiftUI** — declarative UI
- **HealthKit** — Apple Health integration
- **Swift Concurrency** — async/await and actors
- **iOS 16+** — minimum deployment target
- No third-party dependencies

## Troubleshooting

**"Connection failed"** — verify Nightscout URL and API secret match exactly, confirm instance is running.

**"HealthKit authorization denied"** — go to iOS Settings > Privacy & Security > Health > DaAtlas and allow access.

**Data not appearing in Apple Health** — confirm write permissions were granted for each data type and check Sync Logs.

## Disclaimer

For informational purposes only. Always consult your healthcare provider about diabetes management decisions.

## License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.

In short: you can use, modify, and distribute this code freely, but any distributed modifications must also be open source under GPL v3.

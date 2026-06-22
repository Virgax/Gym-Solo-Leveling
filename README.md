# Arise — A Solo Leveling System for the Gym 🗡️📈

Turn your real training and recovery into an RPG. **Arise** is "the System": it
reads your body through Apple Health and turns workouts, steps, sleep, heart
rate and body composition into **XP, Levels, a Hunter Rank, Stats, and Daily
Quests** — Solo-Leveling style.

> Every number traces back to a real metric. No fake points.

## How your devices connect

On iOS, **Apple Health (HealthKit) is the single source of truth**, and your
gear already syncs into it:

| Device | How it reaches the app |
|---|---|
| **Apple Watch / iPhone** | native HealthKit |
| **RingConn** smart ring | two-way sync into Apple Health → sleep, resting HR, HRV, SpO₂, steps |
| **Eufy Life** smart scale | writes to Apple Health → body mass, body-fat %, BMI, lean mass |
| **Fitbit ("Air")** | ⚠️ **not** available on iOS — Fitbit only syncs to **Google Health Connect** on Android. Planned for the Android phase via a `HealthConnectSource` behind the same data layer. |

So you don't integrate RingConn or Eufy directly — they flow through Apple
Health, and Arise reads from there.

## What's in this build (Phase 1)

- 🩺 **HealthKit ingestion** — steps, active energy, exercise minutes, workouts
  (strength vs. cardio), resting HR, HRV, VO₂max, SpO₂, sleep, body composition.
- 🧮 **The formula** — five stats (STR / AGI / VIT / END / SEN), an XP curve,
  rank tiers E → S → Monarch. Fully documented in [`docs/SYSTEM_DESIGN.md`](docs/SYSTEM_DESIGN.md).
- 🎯 **Daily Quests** that scale with your level, with sticky XP payouts.
- ✨ **The System UI** — glowing blue status windows, rank emblem, an "ARISE"
  level-up sequence.
- 🧪 **Sample-data mode** so the whole app is explorable on the Simulator or
  before your ring has synced.

## Running it

1. Open `Arise.xcodeproj` in **Xcode 16+**.
2. Select the **Arise** scheme and a device/Simulator (iOS 17+).
3. Set your **Team** under *Signing & Capabilities* (HealthKit needs a real
   provisioning profile to run on a device).
4. Build & run. Tap **AWAKEN** and grant Health access.

> Real ring/scale/watch data only appears on a physical device that has those
> sources synced into Apple Health. The Simulator shows sample data.

## Architecture

```
Arise/
├── Models/        HunterProfile, Stat, Rank, Quest, HealthSnapshot
├── Engine/        SystemFormula, LevelingEngine, QuestEngine   (pure, testable)
├── Health/        HealthSource protocol, HealthKitSource, MockHealthSource
├── Persistence/   ProfileStore (Codable/UserDefaults)
├── ViewModels/    SystemViewModel (snapshot → engine → persisted progression)
├── Views/         StatusWindow, QuestWindow, LevelUpOverlay, RootView, Components
└── Theme/         SystemTheme
```

The game engine is pure and source-agnostic. Adding Android/Fitbit later means
writing one `HealthConnectSource` that fills the same `HealthSnapshot` — nothing
else changes.

## Roadmap

- **Phase 2:** manual lift logging → true strength *volume* in STR; quest
  penalty zone & streak rewards; widgets / Live Activities; HealthKit background
  delivery.
- **Phase 3:** Android via **Health Connect** to bring in **Fitbit** + Google
  Health through the same engine.

See [`docs/SYSTEM_DESIGN.md`](docs/SYSTEM_DESIGN.md) for the full formula.

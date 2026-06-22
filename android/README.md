# Arise — Android

A native **Jetpack Compose** port of the Arise System, built to be **adaptive
across every form factor**: candy-bar phones, flip phones (folded/unfolded),
foldables, and tablets.

## Adaptive UI

- **Compact width** (phones, flip closed, folded) → bottom **navigation bar**.
- **Expanded width** (tablets, unfolded foldables, landscape) → side
  **navigation rail**.
- Content is width-constrained and centered, so it reads well from a narrow
  flip cover to a wide tablet. Driven by `BoxWithConstraints` (no fragile fixed
  layouts), and `android:resizeableActivity="true"` for multi-window/foldables.

## Data (Health Connect)

On Android the aggregation hub is **Health Connect** — **Fitbit**, **Google
Health**, and the **RingConn** ring all sync there. The current build runs the
full System (rank, level, XP, stats, quests, Gates, fuel/hydration) on a sample
snapshot + what you log; wiring Health Connect reads/writes is the next
milestone (the engine already consumes a source-agnostic `HealthSnapshot`).

## Building

The repo is developed outside Android Studio, and this environment can't reach
Google's SDK/Maven hosts, so **CI builds the APK**:

- GitHub Actions workflow [`.github/workflows/android.yml`](../.github/workflows/android.yml)
  builds `assembleDebug` on every push touching `android/**` and uploads the
  APK as the **`arise-debug-apk`** artifact. Download it from the workflow run's
  *Artifacts* section and install on any Android 8.0+ (API 26) device.

Locally (with Android Studio / SDK):

```bash
cd android
./gradlew assembleDebug      # → app/build/outputs/apk/debug/app-debug.apk
```

## Stack

- Kotlin 2.0 · Jetpack Compose (BOM 2024.09) · Material 3
- minSdk 26 · compileSdk/targetSdk 35 · AGP 8.6 · Gradle 8.10
- Pure-Kotlin domain engine (`domain/`) ported 1:1 from the iOS `SystemFormula`.

# The System — Design & Formula

A "Solo Leveling"-style RPG layer over your real fitness data. The app is the
**System**: it watches your body through HealthKit and turns real activity into
**XP**, **Levels**, a **Hunter Rank**, **Stats**, and **Daily Quests**.

> Design goal: every number on screen traces back to a real health metric. No
> fake points. If we can't measure it honestly, we proxy it and *say so*.

---

## 1. Data sources (all flow through HealthKit on iOS)

| Source | Reaches HealthKit? | Gives us |
|---|---|---|
| Apple Watch / iPhone | ✅ native | steps, distance, active energy, exercise minutes, workouts, HR, HRV, VO₂max |
| **RingConn** smart ring | ✅ two-way sync | sleep stages, resting HR, HRV, SpO₂, steps |
| **Eufy Life** smart scale | ✅ writes to Apple Health | body mass, body fat %, BMI, lean body mass |
| **Fitbit ("Air")** | ❌ *not* on iOS | Android-only via **Health Connect** (Phase 2) |

So on iOS, **HealthKit is the single ingestion point**. The `HealthSnapshot`
model and `HealthSource` protocol are written to be source-agnostic, so a
`HealthConnectSource` (Fitbit, Android) can be added later without touching the
game engine.

---

## 2. Stats (the STATUS window)

Five stats, derived from rolling **30-day** condition plus a permanent **trained
bonus** from your Level (so grinding always nudges every stat up, like the
manhwa).

```
stat = round( condition(0…100) + trainedBonus )      trainedBonus = level * 2
```

| Stat | Drives off | HealthKit metrics |
|---|---|---|
| **STR** Strength | gym / resistance work | strength-training minutes, active energy in strength workouts, lean body mass trend (Eufy) |
| **AGI** Agility | movement & cardio | steps, walking+running distance, cardio workout minutes |
| **VIT** Vitality | cardiovascular health | resting HR (inverse), HRV SDNN, VO₂max |
| **END** Endurance | sustained effort | total exercise minutes, active energy, workout streak |
| **SEN** Sense | recovery & sleep | sleep duration & efficiency, SpO₂, HRV |

`condition` for each stat is a 0–100 normalization of recent performance against
a "strong" daily target (see `SystemFormula.swift` for the exact targets).
Inverse metrics (resting HR) are flipped: lower = higher score.

> **Honest proxy:** HealthKit does not expose set×rep×weight volume unless a
> logging app writes it, so **STR** is proxied from strength-workout *minutes +
> energy + lean mass*. Manual lift logging is a Phase 2 upgrade that will feed a
> true volume term into STR.

A **Condition** modifier from Eufy body-composition (body-fat %, BMI) lightly
scales STR/VIT and is shown as a separate readout.

---

## 3. XP & Leveling

XP is earned **per day** and stored in an idempotent ledger keyed by date, so
re-syncing a day **replaces** that day's metric XP instead of double-counting.

### Daily metric XP
```
xp  =  steps / 200                      // 10k steps ≈ 50 xp
     + activeEnergyKcal * 0.15
     + exerciseMinutes  * 1.5
     + strengthMinutes  * 2.0           // gym emphasis
     + sleepScore                       // 7–9h ≈ 40, scaled, 0 if untracked
```
Quest completions add **sticky** bonus XP (once earned, never recomputed away).

```
totalXP = Σ metricLedger[day]  +  Σ questLedger[day]
```

### Level curve
```
xpToNext(level) = 100 + level * 40       // L1→2 = 140, L2→3 = 180, …
```
Cumulative, so each level costs a bit more. `level` is derived from `totalXP`.

### Rank by level
| Rank | Levels |
|---|---|
| **E** | 1–9 |
| **D** | 10–24 |
| **C** | 25–44 |
| **B** | 45–69 |
| **A** | 70–99 |
| **S** | 100–149 |
| **MONARCH** | 150+ |

---

## 4. Daily Quests

Generated each day from the Hunter's level (targets scale up as you grow). The
System checks progress against today's `HealthSnapshot`. Classic Solo-Leveling
flavor: a fixed daily set, a completion bonus, and (Phase 2) a **penalty zone**
if the day's mandatory quest is missed.

Default daily set (targets scale with level):
- **Train the body** — ≥ N strength minutes
- **Keep moving** — ≥ N steps
- **Burn** — ≥ N kcal active energy
- **Recover** — ≥ 7h sleep

---

## 5. First-launch setup (Onboarding)

The very first launch runs a 4-step flow (`OnboardingView`), gated until
`profile.onboardingComplete`:

1. **Welcome + Health permission** — requests HealthKit read access.
2. **Body metrics** — *prefilled from Apple Health* when available (biological
   sex, date of birth, height, latest weight); anything missing is entered
   manually via sliders/pickers. BMI is shown live.
3. **Goal** — Lose fat / Maintain / Build muscle.
4. **Calibration summary** — the System computes and shows your targets.

Derived math (`HealthMath`, all standard formulas, explained in-app):
- **BMI** = kg / m²
- **BMR** = Mifflin–St Jeor (sex-specific)
- **TDEE** = BMR × activity factor (1.2 … 1.9)
- **Calories** = TDEE shifted by goal (−500 / 0 / +350)
- **Protein** = 1.8–2.0 g/kg · **Water** = ~35 mL/kg (clamped) ·
  **Caffeine ceiling** = min(400 mg, 6 mg/kg)

## 6. Fuel & Hydration tracking

A per-day `DailyLog` (idempotent, keyed by date) tracks:
- **Water** (mL) and **Caffeine** (mg) via quick-add buttons, against targets.
- **Meal schedule** — breakfast, morning snack, lunch, afternoon snack, dinner —
  each with logged items + **calories** (and optional protein). Totals roll up
  to a daily calorie/protein readout vs. target.

These feed XP (`SystemFormula.nutritionXP`) and three **Fuel quests** (Hydrate,
Hit Protein, Fuel the Machine). Going over the caffeine ceiling is surfaced as a
recovery debuff.

> Phase 2: read/write these through HealthKit's dietary types so logs sync both
> ways with Apple Health.

## 7. Gates (Routines & execution)

Inspired by Muscle-Monster-style planners. A **Gate** is a structured routine
(`Routine` → `RoutineExercise` → `Exercise`) with sets, reps, rest and a
difficulty rank. The built-in `RoutineLibrary` ships Push / Pull / Legs /
Full-Body / Core / Home gates.

**Execution** (`GateSessionView`): tap to check off each set, an automatic **rest
timer** counts down between sets, and a progress bar tracks completion. Clearing
a Gate pays `xpReward` (once/day) and adds its minutes to today's **strength**,
so it flows into STR/END and the training quest.

> Phase 2: 1000+ movement library with video cues, AI-generated plans, a custom
> routine builder, and writing the session back to HealthKit as a workout.

## 8. Roadmap

- **Phase 1 (this build):** HealthKit ingestion, formula, leveling, ranks,
  stats, daily quests, the System UI (Status window, quests, level-up "ARISE").
- **Phase 2:** manual lift logging → true STR volume; quest penalty zone &
  streaks; widgets / Live Activities; background delivery refresh.
- **Phase 3:** Android via **Health Connect** (`HealthConnectSource`) to pull
  **Fitbit** + Google Health data through the same `HealthSnapshot`.

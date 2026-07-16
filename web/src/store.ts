import { useCallback, useEffect, useMemo, useState } from "react";
import {
  BodyProfile, DEFAULT_TARGETS, HealthSnapshot, Intake, LevelingEngine, Meal, Routine,
  computeStats, dailyMetricXP, dailyQuests, nutritionXP, questComplete, rankForLevel,
  routineXP, sampleSnapshot, targetsFor,
} from "./engine";

const KEY = "arise.state.v1";
const KEY_TS = "arise.state.ts.v1";

/** Epoch ms of the last local mutation (used for last-write-wins cloud sync). */
export function getLocalTs(): number {
  return Number(localStorage.getItem(KEY_TS) ?? 0);
}

export interface AppState {
  onboardingDone: boolean;
  hunterName: string;
  body: BodyProfile;
  units: "metric" | "imperial";
  day: string;
  waterMl: number;
  caffeineMg: number;
  meals: Meal[];
  clearedGateIds: string[];
  gateMinutes: number;
  bonusXp: number;
  awarded: string[];
}

const todayKey = () => new Date().toISOString().slice(0, 10);

const initial: AppState = {
  onboardingDone: false,
  hunterName: "Hunter",
  body: { sex: "male", age: 25, heightCm: 175, weightKg: 75, activity: "moderate", goal: "maintain" },
  units: "metric",
  day: todayKey(),
  waterMl: 0,
  caffeineMg: 0,
  meals: [],
  clearedGateIds: [],
  gateMinutes: 0,
  bonusXp: 0,
  awarded: [],
};

function load(): AppState {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return initial;
    const s = { ...initial, ...JSON.parse(raw) } as AppState;
    if (s.day !== todayKey()) {
      // New day → reset the daily log, keep profile.
      return { ...s, day: todayKey(), waterMl: 0, caffeineMg: 0, meals: [], clearedGateIds: [], gateMinutes: 0, bonusXp: 0, awarded: [] };
    }
    return s;
  } catch {
    return initial;
  }
}

const uid = () => Math.random().toString(36).slice(2, 10);

export function useArise() {
  const [state, setState] = useState<AppState>(load);

  useEffect(() => {
    try {
      localStorage.setItem(KEY, JSON.stringify(state));
      localStorage.setItem(KEY_TS, String(Date.now()));
    } catch { /* ignore quota */ }
  }, [state]);

  const targets = useMemo(() => (state.onboardingDone ? targetsFor(state.body) : DEFAULT_TARGETS), [state.onboardingDone, state.body]);

  const snapshot: HealthSnapshot = useMemo(
    () => ({ ...sampleSnapshot, strengthMinutesToday: sampleSnapshot.strengthMinutesToday + state.gateMinutes }),
    [state.gateMinutes],
  );

  const intake: Intake = useMemo(() => ({
    waterMl: state.waterMl,
    totalCalories: state.meals.reduce((a, m) => a + m.calories, 0),
    totalProteinG: state.meals.reduce((a, m) => a + m.proteinG, 0),
    mealsLogged: new Set(state.meals.map((m) => m.type)).size,
  }), [state.waterMl, state.meals]);

  const totalXp = useMemo(() => dailyMetricXP(snapshot) + nutritionXP(intake, targets) + state.bonusXp, [snapshot, intake, targets, state.bonusXp]);
  const level = LevelingEngine.level(totalXp);
  const rank = rankForLevel(level);
  const xpProgress = LevelingEngine.progress(totalXp);
  const stats = useMemo(() => computeStats(snapshot, level), [snapshot, level]);
  const quests = useMemo(() => dailyQuests(snapshot, intake, targets, level), [snapshot, intake, targets, level]);

  // Award quest XP once, when a quest first completes.
  useEffect(() => {
    const newly = quests.filter((q) => questComplete(q) && !state.awarded.includes(q.id));
    if (newly.length) {
      setState((s) => ({ ...s, awarded: [...s.awarded, ...newly.map((q) => q.id)], bonusXp: s.bonusXp + newly.reduce((a, q) => a + q.xpReward, 0) }));
    }
  }, [quests, state.awarded]);

  const completeOnboarding = useCallback((name: string, body: BodyProfile) => {
    setState((s) => ({ ...s, hunterName: name.trim() || "Hunter", body, onboardingDone: true }));
  }, []);
  const setUnits = useCallback((units: "metric" | "imperial") => setState((s) => ({ ...s, units })), []);
  const addWater = useCallback((ml: number) => setState((s) => ({ ...s, waterMl: Math.max(0, s.waterMl + ml) })), []);
  const addCaffeine = useCallback((mg: number) => setState((s) => ({ ...s, caffeineMg: Math.max(0, s.caffeineMg + mg) })), []);
  const logMeal = useCallback((m: Omit<Meal, "id">) => setState((s) => ({ ...s, meals: [...s.meals, { ...m, id: uid() }] })), []);
  const removeMeal = useCallback((id: string) => setState((s) => ({ ...s, meals: s.meals.filter((m) => m.id !== id) })), []);
  const completeGate = useCallback((r: Routine) => setState((s) => {
    if (s.clearedGateIds.includes(r.id)) return s;
    const key = `gate.${r.id}`;
    return {
      ...s,
      clearedGateIds: [...s.clearedGateIds, r.id],
      gateMinutes: s.gateMinutes + r.estMinutes,
      bonusXp: s.awarded.includes(key) ? s.bonusXp : s.bonusXp + routineXP(r),
      awarded: s.awarded.includes(key) ? s.awarded : [...s.awarded, key],
    };
  }), []);
  const resetAll = useCallback(() => { localStorage.removeItem(KEY); setState(initial); }, []);
  // Replace the whole state (used when pulling a newer copy from the cloud).
  const replaceState = useCallback((s: AppState) => setState({ ...initial, ...s }), []);

  return {
    state, targets, intake, totalXp, level, rank, xpProgress, stats, quests,
    streak: sampleSnapshot.workoutStreakDays,
    completeOnboarding, setUnits, addWater, addCaffeine, logMeal, removeMeal, completeGate, resetAll, replaceState,
  };
}

export type Arise = ReturnType<typeof useArise>;

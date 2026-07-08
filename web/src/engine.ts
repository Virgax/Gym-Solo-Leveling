// Pure domain engine — ported 1:1 from the iOS (Swift) and Android (Kotlin) apps.

export type RankKey = "E" | "D" | "C" | "B" | "A" | "S" | "MONARCH";

export const RANKS: { key: RankKey; label: string; minLevel: number; color: string }[] = [
  { key: "E", label: "E", minLevel: 1, color: "#8FA6C4" },
  { key: "D", label: "D", minLevel: 10, color: "#4ED2A0" },
  { key: "C", label: "C", minLevel: 25, color: "#35C2FF" },
  { key: "B", label: "B", minLevel: 45, color: "#9B6BFF" },
  { key: "A", label: "A", minLevel: 70, color: "#FFC857" },
  { key: "S", label: "S", minLevel: 100, color: "#FF8A3D" },
  { key: "MONARCH", label: "MONARCH", minLevel: 150, color: "#FF4D6D" },
];

export function rankForLevel(level: number) {
  let r = RANKS[0];
  for (const rank of RANKS) if (level >= rank.minLevel) r = rank;
  return r;
}
export function rankTitle(key: RankKey) {
  return key === "MONARCH" ? "Monarch" : `${key}-Rank Hunter`;
}

export type StatKey = "STR" | "AGI" | "VIT" | "END" | "SEN";
export const STATS: { key: StatKey; name: string; color: string }[] = [
  { key: "STR", name: "Strength", color: "#FF6B6B" },
  { key: "AGI", name: "Agility", color: "#4ED2A0" },
  { key: "VIT", name: "Vitality", color: "#FF4D6D" },
  { key: "END", name: "Endurance", color: "#FF8A3D" },
  { key: "SEN", name: "Sense", color: "#9B6BFF" },
];

export interface HealthSnapshot {
  stepsToday: number;
  activeEnergyToday: number;
  exerciseMinutesToday: number;
  strengthMinutesToday: number;
  sleepHoursLastNight: number | null;
  avgSteps: number;
  avgActiveEnergy: number;
  avgExerciseMinutes: number;
  avgStrengthMinutes: number;
  avgCardioMinutes: number;
  avgDistanceMeters: number;
  avgSleepHours: number;
  workoutStreakDays: number;
  restingHeartRate: number | null;
  hrvSDNN: number | null;
  vo2Max: number | null;
  spo2: number | null;
  bodyMassKg: number | null;
  bodyFatPercentage: number | null;
  leanBodyMassKg: number | null;
}

export const sampleSnapshot: HealthSnapshot = {
  stepsToday: 8200, activeEnergyToday: 540, exerciseMinutesToday: 44, strengthMinutesToday: 38,
  sleepHoursLastNight: 7.4, avgSteps: 9100, avgActiveEnergy: 610, avgExerciseMinutes: 52,
  avgStrengthMinutes: 31, avgCardioMinutes: 24, avgDistanceMeters: 6400, avgSleepHours: 7.1,
  workoutStreakDays: 6, restingHeartRate: 54, hrvSDNN: 78, vo2Max: 48, spo2: 0.97,
  bodyMassKg: 78, bodyFatPercentage: 0.16, leanBodyMassKg: 65.5,
};

// ---- Body & nutrition ----

export type Sex = "male" | "female" | "other";
export const ACTIVITY = {
  sedentary: { factor: 1.2, label: "Sedentary" },
  light: { factor: 1.375, label: "Lightly active" },
  moderate: { factor: 1.55, label: "Moderately active" },
  active: { factor: 1.725, label: "Very active" },
  athlete: { factor: 1.9, label: "Athlete" },
} as const;
export type ActivityKey = keyof typeof ACTIVITY;
export type Goal = "lose" | "maintain" | "gain";
export const GOAL_LABEL: Record<Goal, string> = { lose: "Lose fat", maintain: "Maintain", gain: "Build muscle" };

export interface BodyProfile {
  sex: Sex;
  age: number;
  heightCm: number;
  weightKg: number;
  activity: ActivityKey;
  goal: Goal;
}

export const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));

export const HealthMath = {
  bmi: (w: number, hCm: number) => (hCm <= 0 ? 0 : w / (hCm / 100) ** 2),
  bmiCategory: (bmi: number) => (bmi < 18.5 ? "Underweight" : bmi < 25 ? "Normal" : bmi < 30 ? "Overweight" : "Obese"),
  bmr: (w: number, hCm: number, age: number, sex: Sex) => {
    const base = 10 * w + 6.25 * hCm - 5 * age;
    return sex === "male" ? base + 5 : sex === "female" ? base - 161 : base - 78;
  },
  tdee: (bmr: number, a: ActivityKey) => bmr * ACTIVITY[a].factor,
  calorieTarget: (tdee: number, g: Goal) => Math.round(g === "lose" ? tdee - 500 : g === "gain" ? tdee + 350 : tdee),
  proteinTargetG: (w: number, g: Goal) => Math.round(w * (g === "lose" ? 2.0 : 1.8)),
  waterTargetMl: (w: number) => Math.round(clamp(w * 35, 2000, 4000)),
  caffeineLimitMg: (w: number) => Math.round(Math.min(400, w * 6)),
};

export interface NutritionTargets {
  calories: number;
  proteinG: number;
  waterMl: number;
  caffeineLimitMg: number;
}
export function targetsFor(b: BodyProfile): NutritionTargets {
  const bmr = HealthMath.bmr(b.weightKg, b.heightCm, b.age, b.sex);
  const tdee = HealthMath.tdee(bmr, b.activity);
  return {
    calories: HealthMath.calorieTarget(tdee, b.goal),
    proteinG: HealthMath.proteinTargetG(b.weightKg, b.goal),
    waterMl: HealthMath.waterTargetMl(b.weightKg),
    caffeineLimitMg: HealthMath.caffeineLimitMg(b.weightKg),
  };
}
export const DEFAULT_TARGETS: NutritionTargets = { calories: 2200, proteinG: 120, waterMl: 2500, caffeineLimitMg: 400 };

// ---- Leveling ----

export const LevelingEngine = {
  xpToNext: (fromLevel: number) => 100 + Math.max(0, fromLevel) * 40,
  cumulativeXP(toReach: number) {
    if (toReach <= 1) return 0;
    let total = 0;
    for (let l = 1; l < toReach; l++) total += this.xpToNext(l);
    return total;
  },
  level(totalXP: number) {
    let level = 1;
    while (totalXP >= this.cumulativeXP(level + 1)) level++;
    return level;
  },
  progress(totalXP: number): [number, number] {
    const lvl = this.level(totalXP);
    return [totalXP - this.cumulativeXP(lvl), this.xpToNext(lvl)];
  },
};

// ---- Stats & XP ----

const norm = (v: number | null, target: number) => (v == null || target <= 0 ? 0 : clamp(v / target, 0, 1));
const inverseNorm = (v: number | null, best: number, worst: number) =>
  v == null ? 0 : v <= best ? 1 : v >= worst ? 0 : (worst - v) / (worst - best);
const rampNorm = (v: number | null, lo: number, hi: number) => (v == null || hi <= lo ? 0 : clamp((v - lo) / (hi - lo), 0, 1));
const blend = (a: number, wa: number, b: number, wb: number) => (a * wa + b * wb) / (wa + wb);
const blend3 = (a: number, wa: number, b: number, wb: number, c: number, wc: number) =>
  (a * wa + b * wb + c * wc) / (wa + wb + wc);

function sleepCondition(hours: number) {
  if (hours <= 0) return 0;
  if (hours >= 7 && hours <= 9) return 1;
  if (hours >= 6 && hours < 7) return 0.75;
  if (hours > 9 && hours <= 10) return 0.85;
  if (hours >= 5 && hours < 6) return 0.45;
  return 0.2;
}
function leanQuality(s: HealthSnapshot) {
  if (s.leanBodyMassKg == null || s.bodyMassKg == null || s.bodyMassKg <= 0) return 0.5;
  return clamp((s.leanBodyMassKg / s.bodyMassKg - 0.6) / 0.3, 0, 1);
}

export function statCondition(kind: StatKey, s: HealthSnapshot): number {
  switch (kind) {
    case "STR": return blend(norm(s.avgStrengthMinutes, 35), 0.7, leanQuality(s), 0.3);
    case "AGI": return blend3(norm(s.avgSteps, 11000), 0.45, norm(s.avgDistanceMeters, 7000), 0.25, norm(s.avgCardioMinutes, 30), 0.3);
    case "VIT": return blend3(inverseNorm(s.restingHeartRate, 45, 85), 0.4, norm(s.hrvSDNN, 90), 0.35, norm(s.vo2Max, 50), 0.25);
    case "END": return blend3(norm(s.avgExerciseMinutes, 60), 0.45, norm(s.avgActiveEnergy, 750), 0.3, norm(s.workoutStreakDays, 14), 0.25);
    case "SEN": return blend3(sleepCondition(s.avgSleepHours), 0.55, rampNorm(s.spo2 == null ? null : s.spo2 * 100, 92, 99), 0.2, norm(s.hrvSDNN, 90), 0.25);
  }
}

export interface Stat { key: StatKey; value: number; condition: number; }
export function computeStats(s: HealthSnapshot, level: number): Stat[] {
  const trained = level * 2;
  return STATS.map(({ key }) => {
    const c = statCondition(key, s);
    return { key, value: Math.round(c * 100 + trained), condition: c };
  });
}

function sleepScore(h: number | null) {
  if (h == null || h <= 0) return 0;
  if (h >= 7 && h <= 9) return 40;
  if (h >= 6 && h < 7) return 28;
  if (h > 9 && h <= 10) return 32;
  if (h >= 5 && h < 6) return 16;
  return 8;
}

export interface Intake { waterMl: number; totalCalories: number; totalProteinG: number; mealsLogged: number; }

export function dailyMetricXP(s: HealthSnapshot): number {
  return Math.round(s.stepsToday / 200 + s.activeEnergyToday * 0.15 + s.exerciseMinutesToday * 1.5 + s.strengthMinutesToday * 2 + sleepScore(s.sleepHoursLastNight));
}
export function nutritionXP(i: Intake, t: NutritionTargets): number {
  return Math.round(Math.min(1, i.waterMl / Math.max(1, t.waterMl)) * 20 + Math.min(1, i.totalProteinG / Math.max(1, t.proteinG)) * 25 + i.mealsLogged * 4);
}

// ---- Quests ----

export type QuestCategory = "training" | "fuel" | "recovery";
export interface Quest {
  id: string; title: string; category: QuestCategory;
  target: number; progress: number; unit: string; xpReward: number; mandatory: boolean;
}
export const questFraction = (q: Quest) => (q.target <= 0 ? 1 : Math.min(1, q.progress / q.target));
export const questComplete = (q: Quest) => q.progress >= q.target;

export function dailyQuests(s: HealthSnapshot, i: Intake, t: NutritionTargets, level: number): Quest[] {
  const tier = Math.min(level, 60);
  return [
    { id: "strength", title: "Train the Body", category: "training", target: 20 + tier * 0.5, progress: s.strengthMinutesToday, unit: "min", xpReward: 60, mandatory: true },
    { id: "steps", title: "Keep Moving", category: "training", target: 6000 + tier * 100, progress: s.stepsToday, unit: "steps", xpReward: 40, mandatory: true },
    { id: "burn", title: "Burn", category: "training", target: 350 + tier * 5, progress: s.activeEnergyToday, unit: "kcal", xpReward: 40, mandatory: false },
    { id: "hydrate", title: "Hydrate", category: "fuel", target: t.waterMl, progress: i.waterMl, unit: "mL", xpReward: 35, mandatory: true },
    { id: "protein", title: "Hit Protein", category: "fuel", target: t.proteinG, progress: i.totalProteinG, unit: "g", xpReward: 45, mandatory: false },
    { id: "meals", title: "Fuel the Machine", category: "fuel", target: 3, progress: i.mealsLogged, unit: "meals", xpReward: 30, mandatory: false },
    { id: "recover", title: "Recover", category: "recovery", target: 7, progress: s.sleepHoursLastNight ?? 0, unit: "h", xpReward: 30, mandatory: false },
  ];
}

// ---- Routines (Gates) ----

export interface RoutineExercise { name: string; cue: string; sets: number; reps: string; restSeconds: number; }
export interface Routine { id: string; name: string; subtitle: string; rank: RankKey; estMinutes: number; exercises: RoutineExercise[]; }

export function routineXP(r: Routine): number {
  const totalSets = r.exercises.reduce((a, e) => a + e.sets, 0);
  const rankBonus = RANKS.findIndex((x) => x.key === r.rank) * 25;
  return 60 + totalSets * 6 + rankBonus;
}
export const routineSets = (r: Routine) => r.exercises.reduce((a, e) => a + e.sets, 0);

export const ROUTINES: Routine[] = [
  { id: "push", name: "Push Gate", subtitle: "Chest · Shoulders · Triceps", rank: "D", estMinutes: 45, exercises: [
    { name: "Barbell Bench Press", cue: "Lower to mid-chest, drive up.", sets: 4, reps: "6–10", restSeconds: 120 },
    { name: "Overhead Press", cue: "Brace core, press overhead.", sets: 3, reps: "8–10", restSeconds: 90 },
    { name: "Incline Dumbbell Press", cue: "45° bench, control descent.", sets: 3, reps: "10–12", restSeconds: 75 },
    { name: "Lateral Raise", cue: "Lead with elbows.", sets: 3, reps: "12–15", restSeconds: 60 },
    { name: "Triceps Pushdown", cue: "Elbows pinned, full lockout.", sets: 3, reps: "12–15", restSeconds: 60 },
  ]},
  { id: "pull", name: "Pull Gate", subtitle: "Back · Biceps · Rear delts", rank: "D", estMinutes: 45, exercises: [
    { name: "Pull-Up", cue: "Full hang to chin over bar.", sets: 4, reps: "AMRAP", restSeconds: 120 },
    { name: "Barbell Row", cue: "Hinge ~45°, pull to navel.", sets: 4, reps: "8–10", restSeconds: 90 },
    { name: "Lat Pulldown", cue: "Drive elbows down and back.", sets: 3, reps: "10–12", restSeconds: 75 },
    { name: "Face Pull", cue: "Pull to forehead.", sets: 3, reps: "15–20", restSeconds: 60 },
    { name: "Dumbbell Curl", cue: "No swing, squeeze at top.", sets: 3, reps: "10–12", restSeconds: 60 },
  ]},
  { id: "legs", name: "Leg Gate", subtitle: "Quads · Hamstrings · Glutes", rank: "C", estMinutes: 55, exercises: [
    { name: "Back Squat", cue: "Depth below parallel.", sets: 5, reps: "5–8", restSeconds: 150 },
    { name: "Romanian Deadlift", cue: "Soft knees, push hips back.", sets: 4, reps: "8–10", restSeconds: 120 },
    { name: "Walking Lunge", cue: "Long stride, knee tracks toes.", sets: 3, reps: "12 / leg", restSeconds: 90 },
    { name: "Calf Raise", cue: "Full stretch, pause at top.", sets: 4, reps: "15–20", restSeconds: 60 },
  ]},
  { id: "core", name: "Core Gate", subtitle: "Abs · Obliques · Stability", rank: "E", estMinutes: 20, exercises: [
    { name: "Hanging Knee Raise", cue: "Curl pelvis up.", sets: 3, reps: "12–15", restSeconds: 45 },
    { name: "Cable Crunch", cue: "Round the spine.", sets: 3, reps: "15–20", restSeconds: 45 },
    { name: "Russian Twist", cue: "Rotate from the torso.", sets: 3, reps: "20", restSeconds: 30 },
    { name: "Plank", cue: "Squeeze glutes, hold tight.", sets: 3, reps: "60s", restSeconds: 45 },
  ]},
  { id: "home", name: "Home Gate", subtitle: "No equipment needed", rank: "E", estMinutes: 25, exercises: [
    { name: "Bodyweight Squat", cue: "Chest up, heels down.", sets: 4, reps: "20", restSeconds: 45 },
    { name: "Push-Up", cue: "Lower under control.", sets: 4, reps: "AMRAP", restSeconds: 60 },
    { name: "Reverse Lunge", cue: "Step back, drop the knee.", sets: 3, reps: "12 / leg", restSeconds: 45 },
    { name: "Mountain Climbers", cue: "Fast knees, tight core.", sets: 3, reps: "40s", restSeconds: 30 },
    { name: "Plank", cue: "Neutral spine.", sets: 3, reps: "45s", restSeconds: 30 },
  ]},
];

export const MEAL_TYPES = ["Breakfast", "Morning Snack", "Lunch", "Afternoon Snack", "Dinner"] as const;
export type MealType = (typeof MEAL_TYPES)[number];
export interface Meal { id: string; type: MealType; name: string; calories: number; proteinG: number; }

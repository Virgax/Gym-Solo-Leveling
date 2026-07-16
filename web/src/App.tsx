import { useEffect, useRef, useState } from "react";
import {
  ACTIVITY, ActivityKey, BodyProfile, GOAL_LABEL, Goal, HealthMath, MEAL_TYPES, MealType,
  ROUTINES, RankKey, Routine, STATS, Sex, Stat, Quest, questComplete, questFraction,
  rankForLevel, rankTitle, routineSets, routineXP,
} from "./engine";
import { Arise, useArise } from "./store";
import { Auth, useAuth } from "./auth";
import { useCloudSync } from "./sync";

const STAT_ICON: Record<string, string> = { STR: "🏋️", AGI: "🏃", VIT: "❤️", END: "🔥", SEN: "🌙" };

function Bar({ value, color }: { value: number; color?: string }) {
  return (
    <div className="bar">
      <span style={{ width: `${Math.max(0, Math.min(1, value)) * 100}%`, background: color ? `linear-gradient(90deg, ${color}88, ${color})` : undefined }} />
    </div>
  );
}

function Panel({ title, children, onClick, className }: { title?: string; children: any; onClick?: () => void; className?: string }) {
  return (
    <div className={`panel ${className ?? ""}`} onClick={onClick}>
      {title && <div className="panel-title">{title}</div>}
      {children}
    </div>
  );
}

function RankBadge({ rankKey, size = 64 }: { rankKey: RankKey; size?: number }) {
  const color = { E: "#8FA6C4", D: "#4ED2A0", C: "#35C2FF", B: "#9B6BFF", A: "#FFC857", S: "#FF8A3D", MONARCH: "#FF4D6D" }[rankKey];
  return (
    <div className="rank-badge" style={{ width: size, height: size, ["--c"]: color } as any}>
      <span className="hex-ring" />
      <span className="hex-core" />
      <span className="hex-letter" style={{ fontSize: size / 2.6 }}>{rankKey === "MONARCH" ? "M" : rankKey}</span>
    </div>
  );
}

// ---------- Status ----------
function StatusScreen({ a }: { a: Arise }) {
  const [into, span] = a.xpProgress;
  const b = a.state.body;
  const t = a.targets;
  return (
    <>
      <div className="eyebrow">THE SYSTEM</div>
      <Panel>
        <div className="row">
          <span style={{ fontSize: 20 }}>🔥</span>
          <b>{a.streak > 0 ? `${a.streak}-day streak` : "No active streak"}</b>
          <span className="grow" />
          <span className="muted" style={{ fontSize: 11 }}>Clear daily quests to keep it</span>
        </div>
      </Panel>

      <Panel title="Status">
        <div className="row">
          <RankBadge rankKey={a.rank.key} />
          <div className="grow" style={{ marginLeft: 6 }}>
            <div className="screen-title" style={{ fontSize: 23 }}>{a.state.hunterName}</div>
            <div style={{ color: a.rank.color, fontWeight: 700, letterSpacing: 1, textShadow: `0 0 12px ${a.rank.color}66` }}>{rankTitle(a.rank.key)}</div>
          </div>
          <div style={{ textAlign: "center" }}>
            <div className="muted" style={{ fontSize: 11, fontWeight: 700, letterSpacing: 2 }}>LV</div>
            <div className="lv-num" style={{ fontSize: 42 }}>{a.level}</div>
          </div>
        </div>
        <div className="spread" style={{ margin: "14px 0 4px", fontSize: 11 }}>
          <span className="muted">EXP</span><span className="muted">{into} / {span}</span>
        </div>
        <Bar value={span > 0 ? into / span : 1} />
        <div style={{ height: 1, background: "var(--stroke)", margin: "16px 0" }} />
        {a.stats.map((s: Stat, i: number) => (
          <div key={s.key} style={{ marginBottom: i < a.stats.length - 1 ? 12 : 0 }}>
            <div className="row" style={{ marginBottom: 6 }}>
              <span style={{ width: 24 }}>{STAT_ICON[s.key]}</span>
              <b>{s.key}</b><span className="grow" />
              <span className="stat-num" style={{ color: statColor(s.key), fontSize: 18 }}>{s.value}</span>
            </div>
            <Bar value={s.condition} color={statColor(s.key)} />
          </div>
        ))}
      </Panel>

      <Panel title="Vitals & Targets">
        <div className="grid3">
          <Metric label="BMI" value={HealthMath.bmi(b.weightKg, b.heightCm).toFixed(1)} sub={HealthMath.bmiCategory(HealthMath.bmi(b.weightKg, b.heightCm))} color="var(--accent)" />
          <Metric label="BMR" value={`${Math.round(HealthMath.bmr(b.weightKg, b.heightCm, b.age, b.sex))}`} sub="kcal" color="var(--gold)" />
          <Metric label="TDEE" value={`${Math.round(HealthMath.tdee(HealthMath.bmr(b.weightKg, b.heightCm, b.age, b.sex), b.activity))}`} sub="kcal/day" color="var(--glow)" />
        </div>
        <div style={{ height: 1, background: "var(--stroke)", margin: "14px 0" }} />
        <TargetRow label="Calories" value={`${t.calories} kcal`} sub={GOAL_LABEL[b.goal]} />
        <TargetRow label="Protein" value={`${t.proteinG} g`} sub="muscle fuel" />
        <TargetRow label="Water" value={`${t.waterMl} mL`} sub={`≈${Math.round(t.waterMl / 250)} glasses`} />
        <TargetRow label="Caffeine limit" value={`${t.caffeineLimitMg} mg`} sub="stay under" />
      </Panel>
    </>
  );
}
const statColor = (k: string) => (STATS.find((s) => s.key === k)?.color ?? "var(--accent)");
function Metric({ label, value, sub, color }: { label: string; value: string; sub: string; color: string }) {
  return (
    <div style={{ textAlign: "center" }}>
      <div className="muted" style={{ fontSize: 11, fontWeight: 700 }}>{label}</div>
      <div className="stat-num" style={{ fontSize: 22, color }}>{value}</div>
      <div className="muted" style={{ fontSize: 9 }}>{sub}</div>
    </div>
  );
}
function TargetRow({ label, value, sub }: { label: string; value: string; sub: string }) {
  return (
    <div className="row" style={{ padding: "5px 0" }}>
      <b style={{ fontSize: 14 }}>{label}</b><span className="grow" />
      <span style={{ color: "var(--accent)", fontWeight: 700, fontSize: 14 }}>{value}</span>
      <span className="muted" style={{ fontSize: 11 }}>{sub}</span>
    </div>
  );
}

// ---------- Quests ----------
function QuestsScreen({ a }: { a: Arise }) {
  const groups: [string, Quest["category"]][] = [["Training Quests", "training"], ["Fuel Quests", "fuel"], ["Recovery Quests", "recovery"]];
  return (
    <>
      <div className="eyebrow">DAILY QUESTS</div>
      {groups.map(([title, cat]) => {
        const qs = a.quests.filter((q) => q.category === cat);
        if (!qs.length) return null;
        return (
          <Panel key={cat} title={title}>
            {qs.map((q, i) => (
              <div key={q.id} style={{ marginBottom: i < qs.length - 1 ? 14 : 0, display: "flex", gap: 12 }}>
                <span style={{ width: 20 }}>{questComplete(q) ? "✅" : "⭕️"}</span>
                <div className="grow">
                  <div className="row">
                    <b>{q.title}</b>
                    {q.mandatory && <span style={{ color: "var(--danger)", fontSize: 9, fontWeight: 900 }}>REQ</span>}
                    <span className="grow" />
                    <span style={{ color: "var(--gold)", fontSize: 11, fontWeight: 700 }}>+{q.xpReward} XP</span>
                  </div>
                  <div style={{ margin: "5px 0 3px" }}><Bar value={questFraction(q)} /></div>
                  <div className="muted" style={{ fontSize: 11 }}>{Math.round(q.progress)} / {Math.round(q.target)} {q.unit}</div>
                </div>
              </div>
            ))}
          </Panel>
        );
      })}
    </>
  );
}

// ---------- Fuel ----------
function FuelScreen({ a }: { a: Arise }) {
  const [adding, setAdding] = useState<MealType | null>(null);
  const t = a.targets;
  const eaten = a.intake.totalCalories;
  return (
    <>
      <div className="eyebrow">FUEL</div>
      <Panel title="Daily Fuel">
        <div className="grid3">
          <Metric label="eaten" value={`${eaten}`} sub="kcal" color="var(--text)" />
          <Metric label="target" value={`${t.calories}`} sub="kcal" color="var(--text)" />
          <Metric label="left" value={`${Math.max(0, t.calories - eaten)}`} sub="kcal" color="var(--text)" />
        </div>
        <div style={{ margin: "12px 0 8px" }}><Bar value={t.calories > 0 ? eaten / t.calories : 0} color="#FFC857" /></div>
        <div className="muted" style={{ fontSize: 12 }}>{Math.round(a.intake.totalProteinG)} / {t.proteinG} g protein</div>
      </Panel>

      <Panel title="Hydration">
        <div className="row"><span className="stat-num" style={{ fontSize: 22 }}>{a.state.waterMl} mL</span><span className="muted"> / {t.waterMl} mL</span></div>
        <div style={{ margin: "10px 0 12px" }}><Bar value={t.waterMl > 0 ? a.state.waterMl / t.waterMl : 0} /></div>
        <div className="row" style={{ gap: 10 }}>
          <button className="btn small" onClick={() => a.addWater(250)}>＋ Glass 250</button>
          <button className="btn small" onClick={() => a.addWater(500)}>＋ Bottle 500</button>
          <button className="btn small" onClick={() => a.addWater(-250)}>－ 250</button>
        </div>
      </Panel>

      <Panel title="Caffeine">
        {(() => { const over = a.state.caffeineMg > t.caffeineLimitMg; return (
          <>
            <div className="row"><span className="stat-num" style={{ fontSize: 22, color: over ? "var(--danger)" : "var(--text)" }}>{a.state.caffeineMg} mg</span><span className="muted"> / {t.caffeineLimitMg} mg</span></div>
            <div style={{ margin: "10px 0 12px" }}><Bar value={t.caffeineLimitMg > 0 ? a.state.caffeineMg / t.caffeineLimitMg : 0} color={over ? "#FF4D6D" : "#FFC857"} /></div>
            <div className="row" style={{ gap: 10 }}>
              <button className="btn small" onClick={() => a.addCaffeine(95)}>Coffee 95</button>
              <button className="btn small" onClick={() => a.addCaffeine(63)}>Espresso 63</button>
              <button className="btn small" onClick={() => a.addCaffeine(160)}>Energy 160</button>
            </div>
          </>
        ); })()}
      </Panel>

      <Panel title="Meal Schedule">
        {MEAL_TYPES.map((type) => {
          const items = a.state.meals.filter((m) => m.type === type);
          const kcal = items.reduce((x, m) => x + m.calories, 0);
          return (
            <div key={type} style={{ marginBottom: 8 }}>
              <div className="row">
                <b>{type}</b><span className="grow" />
                {kcal > 0 && <span style={{ color: "var(--gold)", fontSize: 12, fontWeight: 700 }}>{kcal} kcal</span>}
                <button className="btn small" onClick={() => setAdding(type)}>＋</button>
              </div>
              {items.map((m) => (
                <div key={m.id} className="row muted" style={{ fontSize: 12, paddingLeft: 6 }}>
                  <span>• {m.name}</span><span className="grow" /><span>{m.calories} kcal</span>
                  <button className="btn small" style={{ padding: "2px 8px" }} onClick={() => a.removeMeal(m.id)}>✕</button>
                </div>
              ))}
            </div>
          );
        })}
      </Panel>

      {adding && <AddMeal type={adding} onClose={() => setAdding(null)} onSave={(m) => { a.logMeal(m); setAdding(null); }} />}
    </>
  );
}

function AddMeal({ type, onClose, onSave }: { type: MealType; onClose: () => void; onSave: (m: { type: MealType; name: string; calories: number; proteinG: number }) => void }) {
  const [name, setName] = useState("");
  const [cal, setCal] = useState("");
  const [pro, setPro] = useState("");
  const kcal = parseInt(cal) || 0;
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.6)", display: "grid", placeItems: "center", zIndex: 20, padding: 20 }} onClick={onClose}>
      <div className="panel" style={{ maxWidth: 380, width: "100%" }} onClick={(e) => e.stopPropagation()}>
        <div className="panel-title">Log {type}</div>
        <label className="field">What did you eat?</label>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Chicken & rice" />
        <label className="field">Calories (kcal)</label>
        <input value={cal} onChange={(e) => setCal(e.target.value)} inputMode="numeric" />
        <label className="field">Protein (g, optional)</label>
        <input value={pro} onChange={(e) => setPro(e.target.value)} inputMode="numeric" />
        <div className="row" style={{ gap: 10, marginTop: 16 }}>
          <button className="btn grow" onClick={onClose}>Cancel</button>
          <button className="btn primary" disabled={kcal <= 0} onClick={() => onSave({ type, name: name || type, calories: kcal, proteinG: parseFloat(pro) || 0 })}>Add</button>
        </div>
      </div>
    </div>
  );
}

// ---------- Gates ----------
function GatesScreen({ a }: { a: Arise }) {
  const [active, setActive] = useState<Routine | null>(null);
  if (active) return <GateSession routine={active} onClear={() => { a.completeGate(active); setActive(null); }} onBack={() => setActive(null)} />;
  return (
    <>
      <div className="screen-title" style={{ fontSize: 30 }}>GATES</div>
      <div className="muted" style={{ fontSize: 14 }}>Clear a Gate to earn XP and raise STR &amp; END. Each is a structured routine — sets, reps, rest.</div>
      {ROUTINES.map((r) => (
        <Panel key={r.id} className="card-tap" onClick={() => setActive(r)}>
          <div className="row">
            <RankBadge rankKey={r.rank} size={50} />
            <div className="grow" style={{ marginLeft: 6 }}>
              <div className="row"><b style={{ fontSize: 16 }}>{r.name}</b>{a.state.clearedGateIds.includes(r.id) && <span>✅</span>}</div>
              <div className="muted" style={{ fontSize: 12 }}>{r.subtitle}</div>
              <div style={{ color: "var(--accent)", fontSize: 11, marginTop: 4 }}>{r.estMinutes}m · {routineSets(r)} sets · +{routineXP(r)} XP</div>
            </div>
          </div>
        </Panel>
      ))}
    </>
  );
}

function GateSession({ routine, onClear, onBack }: { routine: Routine; onClear: () => void; onBack: () => void }) {
  const [done, setDone] = useState<Record<number, number>>({});
  const total = routineSets(routine);
  const doneSets = routine.exercises.reduce((a, _e, i) => a + (done[i] ?? 0), 0);
  const cleared = doneSets >= total;
  return (
    <>
      <div className="row">
        <button className="btn small" onClick={onBack}>‹ Back</button>
        <span className="grow" />
        <b style={{ color: "var(--accent)" }}>{doneSets} / {total} sets</b>
      </div>
      <div className="screen-title" style={{ fontSize: 24 }}>{routine.name}</div>
      <Bar value={total > 0 ? doneSets / total : 0} />
      {routine.exercises.map((e, i) => (
        <Panel key={i}>
          <div className="row"><span>💪</span><b>{e.name}</b><span className="grow" /><span style={{ color: "var(--gold)", fontWeight: 700, fontSize: 13 }}>{e.reps}</span></div>
          <div className="muted" style={{ fontSize: 12, margin: "6px 0 10px" }}>{e.cue}</div>
          <div className="row" style={{ gap: 10, flexWrap: "wrap" }}>
            {Array.from({ length: e.sets }).map((_, si) => {
              const on = si < (done[i] ?? 0);
              return (
                <button key={si} className={`set-dot ${on ? "on" : ""}`} onClick={() => setDone((d) => ({ ...d, [i]: (d[i] ?? 0) === si + 1 ? si : si + 1 }))}>{si + 1}</button>
              );
            })}
            <span className="grow" />
            <span className="muted" style={{ fontSize: 11 }}>{e.restSeconds}s rest</span>
          </div>
        </Panel>
      ))}
      <button className="btn primary" disabled={!cleared} onClick={onClear}>{cleared ? `CLEAR GATE · +${routineXP(routine)} XP` : "Complete all sets to clear"}</button>
      <div style={{ height: 20 }} />
    </>
  );
}

// ---------- Onboarding (stepped: welcome/login → connect → profile) ----------
function GoogleSignInButton({ auth }: { auth: Auth }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    let tries = 0;
    const id = setInterval(() => {
      if (ref.current && auth.renderButton(ref.current)) clearInterval(id);
      else if (++tries > 50) clearInterval(id);
    }, 100);
    return () => clearInterval(id);
  }, [auth]);
  return <div ref={ref} style={{ display: "flex", justifyContent: "center", minHeight: 44 }} />;
}

const KG_PER_LB = 0.45359237;
const CM_PER_IN = 2.54;
const ftIn = (cm: number) => { const t = Math.round(cm / CM_PER_IN); return `${Math.floor(t / 12)}'${t % 12}"`; };

function Onboarding({ a, auth }: { a: Arise; auth: Auth }) {
  const [step, setStep] = useState(0);
  const [units, setUnits] = useState<"metric" | "imperial">(a.state.units);
  const [name, setName] = useState(auth.user?.email?.split("@")[0] ?? "Hunter");
  const [sex, setSex] = useState<Sex>("male");
  const [age, setAge] = useState(25);
  const [h, setH] = useState(175); // stored in cm
  const [w, setW] = useState(75); // stored in kg
  const [act, setAct] = useState<ActivityKey>("moderate");
  const [goal, setGoal] = useState<Goal>("maintain");

  // Once signed in, move past the welcome step.
  useEffect(() => { if (auth.user && step === 0) setStep(1); }, [auth.user]);

  // Step 0 — Welcome / create account / sign in
  if (step === 0) {
    return (
      <>
        <div style={{ height: 10 }} />
        <div className="eyebrow" style={{ textAlign: "center" }}>THE SYSTEM</div>
        <div className="screen-title" style={{ fontSize: 44, textAlign: "center", lineHeight: 1 }}>ARISE</div>
        <div className="muted" style={{ textAlign: "center", fontSize: 15 }}>
          Turn your training into an RPG. Level up, rank up, clear Gates.
        </div>
        <Panel title="Enter the System">
          {auth.configured ? (
            <>
              <div className="muted" style={{ fontSize: 13, marginBottom: 12 }}>Create your account or sign in to sync your progress across devices.</div>
              <GoogleSignInButton auth={auth} />
              <div className="muted" style={{ textAlign: "center", fontSize: 12, margin: "12px 0" }}>or</div>
              <button className="btn" style={{ width: "100%" }} onClick={() => setStep(1)}>Continue without an account</button>
            </>
          ) : (
            <>
              <div className="muted" style={{ fontSize: 13, marginBottom: 12 }}>Your progress is saved on this device. (Cloud sign-in appears once it's enabled.)</div>
              <button className="btn primary" onClick={() => setStep(1)}>Enter the System</button>
            </>
          )}
        </Panel>
        <div style={{ height: 24 }} />
      </>
    );
  }

  // Step 1 — Connect your data
  if (step === 1) {
    const sources = ["Apple Health", "Google / Health Connect", "Samsung Health", "Oura", "Fitbit", "Garmin"];
    return (
      <>
        <div className="eyebrow">STEP 2 · CONNECT</div>
        <div className="screen-title" style={{ fontSize: 24 }}>Connect your data</div>
        <div className="muted" style={{ fontSize: 14 }}>Link your health sources so you don't type everything — just confirm the numbers.</div>
        <Panel title="Health Sources">
          <div className="row" style={{ gap: 8, flexWrap: "wrap" }}>
            {sources.map((s) => <span key={s} className="chip">{s}</span>)}
          </div>
          <div style={{ height: 12 }} />
          <div className="muted" style={{ fontSize: 12 }}>
            ⚠️ On the web, automatic sync isn't available — browsers can't read Apple / Google / Samsung Health. Use the native app for auto-sync (or a wearable, coming soon). For now, enter your details once.
          </div>
        </Panel>
        <button className="btn primary" onClick={() => setStep(2)}>Set up my profile</button>
        <button className="btn" style={{ width: "100%" }} onClick={() => setStep(0)}>‹ Back</button>
        <div style={{ height: 24 }} />
      </>
    );
  }

  // Step 2 — Profile (with unit toggle)
  const imperial = units === "imperial";
  const bmi = HealthMath.bmi(w, h);
  const tdee = HealthMath.tdee(HealthMath.bmr(w, h, age, sex), act);
  const profile: BodyProfile = { sex, age, heightCm: h, weightKg: w, activity: act, goal };
  return (
    <>
      <div className="eyebrow">STEP 3 · PROFILE</div>
      <div className="screen-title" style={{ fontSize: 24 }}>Your Vessel</div>
      <Panel title="Your Vessel">
        <label className="field">Units</label>
        <div className="row" style={{ gap: 8 }}>
          <button className={`chip ${!imperial ? "sel" : ""}`} onClick={() => setUnits("metric")}>Metric · cm / kg</button>
          <button className={`chip ${imperial ? "sel" : ""}`} onClick={() => setUnits("imperial")}>Imperial · ft / lb</button>
        </div>
        <label className="field">Hunter name</label>
        <input value={name} onChange={(e) => setName(e.target.value)} />
        <label className="field">Sex</label>
        <div className="row" style={{ gap: 8, flexWrap: "wrap" }}>
          {(["male", "female", "other"] as Sex[]).map((s) => <button key={s} className={`chip ${sex === s ? "sel" : ""}`} onClick={() => setSex(s)}>{s}</button>)}
        </div>
        <Slider label={`Age · ${age}`} v={age} min={14} max={90} onChange={setAge} />
        {imperial
          ? <Slider label={`Height · ${ftIn(h)}`} v={Math.round(h / CM_PER_IN)} min={48} max={84} onChange={(inch) => setH(inch * CM_PER_IN)} />
          : <Slider label={`Height · ${Math.round(h)} cm`} v={Math.round(h)} min={120} max={220} onChange={setH} />}
        {imperial
          ? <Slider label={`Weight · ${Math.round(w / KG_PER_LB)} lb`} v={Math.round(w / KG_PER_LB)} min={77} max={440} onChange={(lb) => setW(lb * KG_PER_LB)} />
          : <Slider label={`Weight · ${Math.round(w)} kg`} v={Math.round(w)} min={35} max={200} onChange={setW} />}
        <label className="field">Activity</label>
        <div className="row" style={{ gap: 8, flexWrap: "wrap" }}>
          {(Object.keys(ACTIVITY) as ActivityKey[]).map((k) => <button key={k} className={`chip ${act === k ? "sel" : ""}`} onClick={() => setAct(k)}>{ACTIVITY[k].label}</button>)}
        </div>
        <label className="field">Goal</label>
        <div className="row" style={{ gap: 8, flexWrap: "wrap" }}>
          {(["lose", "maintain", "gain"] as Goal[]).map((g) => <button key={g} className={`chip ${goal === g ? "sel" : ""}`} onClick={() => setGoal(g)}>{GOAL_LABEL[g]}</button>)}
        </div>
      </Panel>
      <Panel title="System Calibration">
        <div style={{ color: "var(--accent)", fontWeight: 700 }}>BMI {bmi.toFixed(1)} ({HealthMath.bmiCategory(bmi)})</div>
        <div className="muted" style={{ fontSize: 13 }}>TDEE {Math.round(tdee)} kcal/day · BMI = kg/m² (WHO)</div>
      </Panel>
      <button className="btn primary" onClick={() => { a.setUnits(units); a.completeOnboarding(name, profile); }}>AWAKEN</button>
      <button className="btn" style={{ width: "100%" }} onClick={() => setStep(1)}>‹ Back</button>
      <div style={{ height: 24 }} />
    </>
  );
}
function Slider({ label, v, min, max, onChange }: { label: string; v: number; min: number; max: number; onChange: (n: number) => void }) {
  return (
    <>
      <label className="field">{label}</label>
      <input className="range" type="range" min={min} max={max} value={v} onChange={(e) => onChange(parseInt(e.target.value))} />
    </>
  );
}

// ---------- Account / Auth ----------
function AccountBar({ auth, onLogin }: { auth: Auth; onLogin: () => void }) {
  if (!auth.configured) return null;
  if (auth.user) {
    return (
      <div className="panel row" style={{ padding: "10px 14px" }}>
        <span>☁️</span>
        <div className="grow">
          <div style={{ fontSize: 13, fontWeight: 700 }}>Synced</div>
          <div className="muted" style={{ fontSize: 11 }}>{auth.user.email}</div>
        </div>
        <button className="btn small" onClick={() => auth.signOut()}>Sign out</button>
      </div>
    );
  }
  return (
    <div className="panel row card-tap" style={{ padding: "10px 14px" }} onClick={onLogin}>
      <span>☁️</span><b className="grow" style={{ fontSize: 13 }}>Sign in to sync your progress</b><span className="muted">›</span>
    </div>
  );
}

function LoginModal({ auth, onClose }: { auth: Auth; onClose: () => void }) {
  const btnRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    let tries = 0;
    const id = setInterval(() => {
      if (btnRef.current && auth.renderButton(btnRef.current)) clearInterval(id);
      else if (++tries > 50) clearInterval(id); // give up after ~5s
    }, 100);
    return () => clearInterval(id);
  }, [auth]);
  return (
    <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.6)", display: "grid", placeItems: "center", zIndex: 20, padding: 20 }} onClick={onClose}>
      <div className="panel" style={{ maxWidth: 380, width: "100%" }} onClick={(e) => e.stopPropagation()}>
        <div className="panel-title">Sign in to sync</div>
        <div ref={btnRef} style={{ display: "flex", justifyContent: "center", minHeight: 44, margin: "8px 0" }} />
        <div className="muted" style={{ fontSize: 12, textAlign: "center" }}>
          Your progress syncs to your account across devices. Apple &amp; email sign-in coming soon.
        </div>
        <button className="btn small" style={{ marginTop: 14, width: "100%" }} onClick={onClose}>Close</button>
      </div>
    </div>
  );
}

// ---------- Shell ----------
type Tab = "status" | "gates" | "fuel" | "quests";
const TABS: { key: Tab; label: string; icon: string }[] = [
  { key: "status", label: "Status", icon: "🧬" },
  { key: "gates", label: "Gates", icon: "⛩️" },
  { key: "fuel", label: "Fuel", icon: "🍽️" },
  { key: "quests", label: "Quests", icon: "✅" },
];

export default function App() {
  const a = useArise();
  const auth = useAuth();
  useCloudSync(auth.jwt, a.state, a.replaceState);
  const [tab, setTab] = useState<Tab>("status");
  const [showLogin, setShowLogin] = useState(false);

  const account = auth.configured ? <AccountBar auth={auth} onLogin={() => setShowLogin(true)} /> : null;
  const loginModal = showLogin ? <LoginModal auth={auth} onClose={() => setShowLogin(false)} /> : null;

  if (!a.state.onboardingDone) {
    return (
      <div className="content">
        <div className="content-inner">
          <Onboarding a={a} auth={auth} />
        </div>
      </div>
    );
  }
  return (
    <div className="shell">
      <nav className="nav">
        {TABS.map((tb) => (
          <button key={tb.key} className={tab === tb.key ? "active" : ""} onClick={() => setTab(tb.key)}>
            <span className="ico">{tb.icon}</span>{tb.label}
          </button>
        ))}
      </nav>
      <main className="content">
        <div className="content-inner">
          {account}
          {tab === "status" && <StatusScreen a={a} />}
          {tab === "gates" && <GatesScreen a={a} />}
          {tab === "fuel" && <FuelScreen a={a} />}
          {tab === "quests" && <QuestsScreen a={a} />}
        </div>
      </main>
      {loginModal}
    </div>
  );
}

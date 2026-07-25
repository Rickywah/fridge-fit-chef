# Protein Powder Supplement Zone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users log today’s whey servings so meal protein targets drop by that amount while carb/fat stay at 40% of daily.

**Architecture:** Persist supplement catalog + daily intake log in localStorage. Add `getTodaySupplementProtein()` and `effectiveMealTargets()` wrapping existing `mealTargets`. Wire Today card + Mine editor; point `buildMealPlan` / `buildAdHocMeal` (and recommend rings) at effective targets. Protein-powder only; no fridge integration.

**Tech Stack:** Single-file vanilla JS in `web/fridge-fit-chef.html`; PowerShell smoke; optional Node verify under `.superpowers/sdd/` (gitignored).

**Spec:** [`docs/superpowers/specs/2026-07-25-supplement-protein-design.md`](../specs/2026-07-25-supplement-protein-design.md)

## Global Constraints

- Only protein powder; no creatine/etc.
- Deduct only when today’s log has servings > 0.
- Deduct **meal protein only**: `max(0, round(dailyP×0.4) − round(suppP))`; C/F unchanged from base mealTargets.
- Built-in seed: id `whey-default`, name `乳清蛋白粉`, `proteinPerServing: 21`.
- Log keyed by local `YYYY-MM-DD`; mismatch resets intakes.
- Custom C/F are display-only in v1 (do not subtract from meal C/F).
- Do not change TDEE, nutrition100, servingScale, or inventory.
- Commit with `git -c user.name="华志盛" -c user.email="2690953291@qq.com" commit` when plan steps say commit; never push unless asked.
- PowerShell: use `;` not `&&`.

## File map

| File | Responsibility |
|------|----------------|
| `web/fridge-fit-chef.html` | Data, calc, Today card, Mine editor, recommend targets |
| `tests/smoke.ps1` | Markers |
| `docs/CHANGELOG-product.md` | User-visible line |

---

### Task 1: Storage, helpers, effectiveMealTargets

**Files:**
- Modify: `web/fridge-fit-chef.html` (`STORAGE_KEYS` ~1746, `state` ~1757, `loadState`, Nutrition near `mealTargets` ~2300)
- Modify: `tests/smoke.ps1`

**Interfaces:**
- `STORAGE_KEYS.supplements = 'ffc_supplements'`
- `STORAGE_KEYS.supplementLog = 'ffc_supplement_log'`
- `SUPPLEMENT_SEED` as in spec
- `state.supplements` array; `state.supplementLog` `{ date, intakes }`
- `function todayDateStr()` → local `YYYY-MM-DD`
- `function ensureSupplementLog()` → reset if date mismatch; return log
- `function getSupplementById(id)`
- `function getTodaySupplementProtein()` → number (sum servings × proteinPerServing)
- `function setSupplementServings(id, servings)` → clamp ≥0, step 0.5, save log
- `function effectiveMealTargets(daily, ratio)` → `{ protein, carb, fat, kcal, supplementProtein }`
- `loadState` / `saveSupplements` / `saveSupplementLog`
- Merge seed on load: ensure `whey-default` exists; keep user overrides of same id fields

Replace call sites that do:
```javascript
var targets = mealTargets(daily, MEAL_RATIO);
targets.kcal = nutKcal(targets);
```
with `effectiveMealTargets(daily, MEAL_RATIO)` in `buildMealPlan` and `buildAdHocMeal` (search both). Keep raw `mealTargets` for any display that needs undeducted baseline if needed; recommend path uses effective only.

- [ ] **Step 1: Failing smoke**

```powershell
  @{ name = "SUPPLEMENT_SEED"; pattern = "SUPPLEMENT_SEED" },
  @{ name = "effectiveMealTargets"; pattern = "function effectiveMealTargets" },
  @{ name = "getTodaySupplementProtein"; pattern = "function getTodaySupplementProtein" },
  @{ name = "whey default 21"; pattern = "proteinPerServing:\s*21" }
```

- [ ] **Step 2: Implement seed, load/save, helpers, switch plan builders to effective targets.**

- [ ] **Step 3: Node verify** `.superpowers/sdd/supplement-verify.js`  
  Stub daily `{ protein:154, carb:200, fat:60 }`, log 1×21g → effective protein `41` (`62−21`), carb/fat unchanged; empty log → protein `62`.

- [ ] **Step 4: Smoke PASS + commit**  
  `Add supplement protein helpers and deduct from meal targets.`

---

### Task 2: Today page supplement card + recommend badge

**Files:**
- Modify: `web/fridge-fit-chef.html` (after activity card in `#panel-today` ~1143; `renderTodayHero` / new `renderSupplementCard`; `renderRecommendResult` gap/day-total)

**UI (Today):**
```html
<div class="card" id="supplement-card">
  <h2>蛋白粉</h2>
  <div id="supplement-list"></div>
  <p class="subtitle" id="supplement-summary"></p>
</div>
```

- Each row: name, `每份 XXg 蛋白`, steppers `−` / servings / `+` (0.5 step)
- Summary: `今日补剂蛋白合计 XXg` or `今日未计蛋白粉`
- On change: save log; `renderSupplementCard`; if `state.currentRecommendation` refresh rings via `renderRecommendResult` (no reshuffle)
- Call `renderSupplementCard` from `switchTab('today')` / `updateActivityChips` / init refresh

**Recommend:**
- If `targets.supplementProtein > 0` (store on rec at build time as `rec.supplementProtein` or recompute live): show `已计入蛋白粉 −XXg`

- [ ] **Step 1: Smoke**

```powershell
  @{ name = "supplement-card"; pattern = 'id="supplement-card"' },
  @{ name = "supplement badge copy"; pattern = "已计入蛋白粉" }
```

- [ ] **Step 2: Implement card + badge + wire events**

- [ ] **Step 3: Smoke PASS + commit**  
  `Add Today protein powder card and recommend supplement badge.`

---

### Task 3: Mine editor for whey presets

**Files:**
- Modify: `web/fridge-fit-chef.html` (Mine section near settings / after 周期目标)

**UI:**
- Section title `蛋白粉`
- List supplements: edit `proteinPerServing` (number); custom entries editable name; delete custom only (not `whey-default`)
- Button `+ 添加蛋白粉` → sheet: name + P/份 (required)
- Save → `saveSupplements()` + toast; refresh Today card if visible

- [ ] **Step 1: Smoke**

```powershell
  @{ name = "supplement mine section"; pattern = "蛋白粉" }
```
(Ensure distinct from Today h2 if needed: e.g. `id="mine-supplements"`)

Prefer: `id="mine-supplements"` in smoke.

- [ ] **Step 2: Implement CRUD UI**

- [ ] **Step 3: Commit**  
  `Add Mine editor for protein powder presets.`

---

### Task 4: Changelog + acceptance

**Files:**
- `docs/CHANGELOG-product.md`
- Spec status → `已实施`
- Full smoke + Node verify

Changelog:

```markdown
## 2026-07 — 蛋白粉补剂

### 新增 / 变更

- 今天可登记已喝蛋白粉；这顿推荐蛋白目标按已摄入扣减
```

Acceptance:
1. No log → meal P = daily×40%  
2. 1×21g → meal P drops ~21  
3. Edit per-serving P → deduct updates  
4. Date change clears  
5. Custom powder works  
6. C/F unchanged  
7. Smoke passes  

- [ ] **Step 1–3:** docs, verify, commit `Document protein powder supplement feature.`

---

## Spec coverage

| Spec item | Task |
|-----------|------|
| Seed + log + effective targets | 1 |
| Today card + recommend badge | 2 |
| Mine editor | 3 |
| Changelog / acceptance | 4 |

## Placeholder scan

None. No GitHub push in steps.

---

## Execution handoff

Plan: `docs/superpowers/plans/2026-07-25-supplement-protein.md`

1. **Subagent-Driven (recommended)**  
2. **Inline Execution**  

Which approach?

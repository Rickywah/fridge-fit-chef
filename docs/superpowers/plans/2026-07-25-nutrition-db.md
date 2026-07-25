# Nutrition DB + Serving Scale Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every built-in food independent per-100g macros, compute recipe/ad-hoc nutrition from grams, and add 0.5× / 1× / 1.5× serving controls that rescale display and inventory deduct.

**Architecture:** Extend `FOOD_DB` in-place with `id`, `state`, `nutrition100`, `source`. Replace `calcRecipeNutrition` / `estimateItemNutrition` to prefer `nutrition100`, falling back to custom `p100` then `CAT_NUTRITION` (marked estimated). UI stores `state.servingScale` and re-renders recommend/recipe views; deduct multiplies ingredient quantities by scale and blocks when stock is insufficient.

**Tech Stack:** Single-file vanilla JS in `web/fridge-fit-chef.html`; smoke checks via `tests/smoke.ps1`.

**Spec:** [`docs/superpowers/specs/2026-07-25-nutrition-db-design.md`](../specs/2026-07-25-nutrition-db-design.md)

## Global Constraints

- Offline only: curated China food-composition-style values; no nutrition API.
- Inventory defaults to **raw** weights; cooked items are separate entries (`熟鸡胸肉`, existing `熟米饭`).
- Fields per 100g: `protein`, `carb`, `fat`, `kcal` (source kcal; do not force 4/4/9 equality).
- Do not delete legacy `recipe.nutrition` fields; normal path must ignore them.
- Do not commit unless the user explicitly asks.
- Do not implement TDEE, goal modes, or auto protein substitution.
- Disclaimer copy somewhere visible: 饮食规划估算，非医疗用途.

## File map

| File | Responsibility |
|------|----------------|
| `web/fridge-fit-chef.html` | FOOD_DB, nutrition helpers, recipe calc, serving UI, deduct |
| `tests/smoke.ps1` | Static markers for `nutrition100`, serving scale |
| `docs/CHANGELOG-product.md` | One user-visible line |

---

### Task 1: Extend FOOD_DB with nutrition100 + new cuts

**Files:**
- Modify: `web/fridge-fit-chef.html` (`FOOD_DB`, `FOOD_EMOJI`, `NAME_ALIASES`, `PROTEIN_KEYS`, `NUTRITION_DATA_VERSION`)
- Modify: `tests/smoke.ps1`

**Interfaces:**
- Produces: every `FOOD_DB` row has `{ id, name, state, unit, grams, cat, nutrition100:{protein,carb,fat,kcal}, source }`
- New foods: `带皮鸡腿肉`, `瘦牛肉`, `肥牛片`, `五花肉`, `熟鸡胸肉`
- Keep display name `牛肉` with lean-beef-equivalent `nutrition100` for old inventory; alias `瘦牛肉` optional reverse not required
- Aliases: `'牛肉片':'肥牛片'` optional; keep existing aliases

**Nutrition values (use these exact macros for distinctive acceptance cases):**

| name | P | C | F | kcal | notes |
|------|---|---|---|------|-------|
| 鸡胸肉 | 23.1 | 0 | 1.9 | 110 | raw |
| 去皮鸡腿肉 | 20.0 | 0 | 5.0 | 125 | raw |
| 带皮鸡腿肉 | 17.0 | 0 | 13.0 | 185 | new; must differ clearly from 鸡胸 |
| 瘦牛肉 | 22.0 | 0 | 4.0 | 125 | new preferred |
| 牛肉 | 22.0 | 0 | 4.0 | 125 | keep name; same as lean |
| 肥牛片 | 16.0 | 0 | 20.0 | 240 | new; must differ from 瘦牛肉 |
| 五花肉 | 9.0 | 0 | 50.0 | 480 | new |
| 熟鸡胸肉 | 30.0 | 0 | 3.0 | 145 | cooked |
| 熟米饭 | 2.6 | 25.9 | 0.3 | 116 | existing cooked |
| 鸡蛋 | 13.3 | 1.5 | 8.8 | 139 | |
| 橄榄油 | 0 | 0 | 100 | 899 | |

For all other existing FOOD_DB rows, assign plausible China-table-style per-100g values consistent with category (vegetables low P/C, staples high C, seafood ~18–22P low F, tofu ~8P, etc.). Every row must have `nutrition100` filled — no built-in left on category-only path.

- [ ] **Step 1: Add smoke checks (expect FAIL)**

```powershell
  @{ name = "nutrition100 field"; pattern = "nutrition100" },
  @{ name = "nutrition data version"; pattern = "NUTRITION_DATA_VERSION" },
  @{ name = "skinned chicken leg"; pattern = "带皮鸡腿肉" },
  @{ name = "fatty beef"; pattern = "肥牛片" }
```

Run: `powershell -File tests/smoke.ps1` → FAIL on new checks.

- [ ] **Step 2: Add version constant + extend FOOD_DB**

Near FOOD_DB:

```javascript
var NUTRITION_DATA_VERSION = '2026-07';
var NUTRITION_SOURCE_DEFAULT = '中国食物成分表口径（规划估算）';
```

Rewrite each FOOD_DB object to include `id`, `state` (`raw`|`cooked`|`n/a`), `nutrition100`, `source: NUTRITION_SOURCE_DEFAULT`. Add the five new foods. Update `FOOD_EMOJI` / `PROTEIN_KEYS` for new names.

- [ ] **Step 3: Re-run smoke** → new checks PASS.

- [ ] **Step 4: Manual sanity** — in console or temporary log, `estimateItemNutrition` not required yet; confirm FOOD_DB length increased and 鸡胸 vs 带皮鸡腿 fat differs in raw data.

---

### Task 2: Nutrition lookup + recipe/ad-hoc calc from grams

**Files:**
- Modify: `web/fridge-fit-chef.html` (`getFoodNutrition100`, rewrite `estimateItemNutrition`, `calcRecipeNutrition`, ad-hoc display path)

**Interfaces:**
- Consumes: FOOD_DB `nutrition100`, custom `p100/c100/f100`
- Produces:
  - `function getFoodNutrition100(name, unit)` → `{ protein, carb, fat, kcal, estimated: boolean }`
  - `function estimateItemNutrition(item)` → macros for `item.quantity` (uses grams)
  - `function calcRecipeNutrition(recipe, scale)` → `{ protein, carb, fat, kcal, estimated }` with `scale` default `1`
  - `function scaleIngredients(ingredients, scale)` → new array with `quantity * scale`

Lookup order in `getFoodNutrition100`:
1. `getAllFoods()` match by resolved name (+ unit if multiple)
2. Else custom `p100` → build object; `kcal = p*4+c*4+f*9` if missing
3. Else `CAT_NUTRITION[cat]` + `estimated: true`; synthesize kcal via 4/4/9

`calcRecipeNutrition(recipe, scale)`:
```javascript
function calcRecipeNutrition(recipe, scale) {
  scale = scale == null ? 1 : scale;
  var total = { protein: 0, carb: 0, fat: 0, kcal: 0 };
  var estimated = false;
  (recipe.ingredients || []).forEach(function (ing) {
    var n = estimateItemNutrition({
      name: ing.name,
      unit: ing.unit,
      quantity: ing.quantity * scale,
      gramsPerUnit: defaultGrams(ing.name, ing.unit)
    });
    // estimateItemNutrition must return kcal too
    total.protein += n.protein;
    total.carb += n.carb;
    total.fat += n.fat;
    total.kcal += n.kcal;
    if (n.estimated) estimated = true;
  });
  var rounded = roundNut(total);
  rounded.kcal = Math.round(total.kcal);
  rounded.estimated = estimated;
  return rounded;
}
```

Do **not** early-return `recipe.nutrition`.

Ad-hoc: when all items non-estimated, show single-value macros (same as recipe path) instead of `formatNutRange`; if any estimated, keep range **or** single value +「含估算项」per spec (prefer single value + flag for consistency).

- [ ] **Step 1: Extend smoke**

```powershell
  @{ name = "getFoodNutrition100"; pattern = "function getFoodNutrition100" },
  @{ name = "calcRecipeNutrition scale"; pattern = "function calcRecipeNutrition" }
```

- [ ] **Step 2: Implement helpers; update all `calcRecipeNutrition(r)` call sites to tolerate extra fields (`estimated`, `kcal`).**

- [ ] **Step 3: Verify** — 200g 鸡胸肉 vs 200g 带皮鸡腿肉 fat differs when calling `estimateItemNutrition`. Recipe r4 (鸡胸) nutrition changes from hardcoded if data differs — acceptable.

- [ ] **Step 4: Smoke PASS.**

---

### Task 3: Serving scale state + UI on recommend + recipe detail

**Files:**
- Modify: `web/fridge-fit-chef.html` (state, CSS, `renderRecommendResult`, recipe detail sheet, deduct)

**Interfaces:**
- `state.servingScale` number, default `1`
- `function servingScaleChipsHtml(active)` → half / standard / boost buttons
- `function canMakeRecipeAtScale(recipe, scale)` → boolean using `ing.quantity * scale` vs inventory map
- `deductInventoryFromPlan(meals, scale)` multiplies required qty by scale; returns insufficient message if short

**UI copy:**
- 半份 (0.5) / 标准 (1) / 加量 (1.5)
- Show scaled ingredient lines via `formatIngLine` on scaled qty
- Macro rings use `calcRecipeNutrition` / meal nutrition × scale (recompute, don’t fake-multiply stale hardcoded)
- If `!canMake` at current scale: show tip `当前份量库存不足` and disable or no-op「标记这顿已完成」with toast
- Disclaimer near day-total or mine: `营养为饮食规划估算，非医疗用途`
- Estimated badge: `含估算项` when `nutrition.estimated`

**Recommend flow:**
1. On `renderRecommendResult`, reset or keep `state.servingScale` (reset to 1 when new recommendation id).
2. Chip click → set scale → `renderRecommendResult(state.currentRecommendation)` without reshuffle.
3. `btn-done` → `deductInventoryFromPlan(..., state.servingScale)`.

**Recipe library detail:** same chips; display-only deduct N/A unless “加入计划” exists — detail view only shows scaled nutrition + ingredients.

- [ ] **Step 1: CSS for `.serving-scale` chip group** (reuse `.chip` / amber active).

- [ ] **Step 2: Wire state + chips into `renderRecommendResult` and recipe detail.**

- [ ] **Step 3: Update `deductInventoryFromPlan` to accept `scale` (default 1).**

- [ ] **Step 4: Manual** — generate meal, switch 1.5× with low stock → blocked deduct; 0.5× succeeds and halves stock.

- [ ] **Step 5: Smoke** add:

```powershell
  @{ name = "servingScale state"; pattern = "servingScale" }
```

---

### Task 4: Changelog + final verification

**Files:**
- Modify: `docs/CHANGELOG-product.md`
- Run: `tests/smoke.ps1`

- [ ] **Step 1: Changelog line**

```markdown
- 食材独立每100g营养；菜谱/组合餐按克重重算；推荐与菜谱支持半份/标准/加量
```

- [ ] **Step 2: Full smoke PASS.**

- [ ] **Step 3: Acceptance checklist from spec §验收标准 (1–8).**

---

## Spec coverage

| Spec item | Task |
|-----------|------|
| FOOD_DB nutrition100 + cuts | 1 |
| Lookup priority + estimated flag | 2 |
| Dynamic recipe/ad-hoc calc | 2 |
| Serving 0.5/1/1.5 UI + deduct | 3 |
| Disclaimer | 3 |
| Smoke + changelog | 1, 3, 4 |
| No TDEE / substitution | Global |

## Placeholder scan

No TBD. Commit steps omitted (ask user before `git commit` / push; user said no GitHub push for now).

---

## Execution handoff

Plan saved to `docs/superpowers/plans/2026-07-25-nutrition-db.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task  
2. **Inline Execution** — this session with checkpoints  

Which approach?

# Cantonese Food DB Expand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add ~50 Cantonese high-frequency foods to `FOOD_DB` with per-100g nutrition, emojis, and aliases; fix the erroneous 鲈鱼→巴沙 alias; no new recipes.

**Architecture:** Data-only expansion in `web/fridge-fit-chef.html`: append `FOOD_DB` rows, extend `FOOD_EMOJI` / `NAME_ALIASES` / `PROTEIN_KEYS` / `UNITS` / `POPULAR_KEYS`. Reuse existing `NUTRITION_SOURCE_DEFAULT` and catalog rendering.

**Tech Stack:** Single-file vanilla JS; PowerShell smoke.

**Spec:** [`docs/superpowers/specs/2026-07-25-cantonese-foods-expand-design.md`](../specs/2026-07-25-cantonese-foods-expand-design.md)

## Global Constraints

- Exactly the 50 formal names in the spec (plus aliases). No new recipes / RECIPE_EMOJI overhaul.
- Every new row: `id`, `name`, `state`, `unit`, `grams`, `cat`, `nutrition100:{protein,carb,fat,kcal}`, `source: NUTRITION_SOURCE_DEFAULT`.
- Remove `'鲈鱼': '巴沙鱼柳'` from `NAME_ALIASES`.
- `排骨`: `unit: '块', grams: 250` (not 斤).
- `莲藕`: `unit: '块', grams: 300` (avoid new 节 if possible); `带鱼` use `块`; `鱿鱼` use `只` — add `只`/`罐` to `UNITS` if used (`罐` for 午餐肉).
- Plausible China-table-style macros; kcal from table style, not forced 4/4/9.
- Commit with `git -c user.name="华志盛" -c user.email="2690953291@qq.com" commit`; never push unless asked.
- PowerShell: `;` not `&&`.

## File map

| File | Role |
|------|------|
| `web/fridge-fit-chef.html` | FOOD_DB, emojis, aliases, keys, units |
| `tests/smoke.ps1` | Name markers |
| `docs/CHANGELOG-product.md` | User line |

---

### Task 1: Add FOOD_DB rows + aliases + emoji + keys

**Files:** Modify `web/fridge-fit-chef.html`, `tests/smoke.ps1`

**Steps:**

- [ ] **Step 1: Failing smoke** — add checks for `菜心`, `鲈鱼` as FOOD_DB name (pattern like `name: '菜心'`), `排骨`, and negative or presence that 鲈鱼 is no longer only an alias to 巴沙 — e.g. pattern `name: '鲈鱼'` in FOOD_DB and ensure alias line `'鲈鱼':\s*'巴沙鱼柳'` is **absent** (add a negative check in `$negativeChecks`).

```powershell
  @{ name = "choy sum"; pattern = "name: '菜心'" },
  @{ name = "sea bass food"; pattern = "name: '鲈鱼'" },
  @{ name = "pork ribs"; pattern = "name: '排骨'" },
  @{ name = "shanghai bok choy"; pattern = "name: '上海青'" }
```

Negative:
```powershell
  @{ name = "no bass-as-basa alias"; pattern = "'鲈鱼'\s*:\s*'巴沙鱼柳'" }
```

- [ ] **Step 2: Append all 50 FOOD_DB objects** (group near related cats). Assign unique kebab `id`s (e.g. `choy-sum`, `sea-bass-raw`, `pork-ribs-raw`).

Suggested macros (P/C/F/kcal per 100g) — use these unless you have better table values; keep consistent style:

Vegetables/greens ~1–3P, 2–6C, 0–0.5F, low kcal; bitter melon ~1P/3C; lotus root ~2P/15C; yam ~2P/12C; taro ~2P/18C; asparagus ~2.5P/3C; snow peas ~3P/7C; edamame ~13P/7C; sprouts ~3P/3C; fuzhu ~45P/20C/15F dry; king oyster ~2P/5C; wood ear ~1.5P/6C; kelp ~1P/3C; cherry tomato ~1P/4C.

Fish ~16–20P, 0–8F; milkfish-style lean ~18P/2F; fatty ~18P/8F; squid ~15P/1F.

Meats: ribs ~15P/20F; pork shank ~20P/8F; beef brisket ~15P/15F; beef tendon ~20P/5F; lamb slice ~16P/15F; chicken feet ~16P/12F; wing root ~17P/12F; duck leg ~16P/15F; pigeon ~20P/8F; quail egg ~13P/11F; salted egg ~14P/12F; century egg ~14P/10F; spam ~12P/25F; milk ~3P/5C/3F kcal~54.

- [ ] **Step 3: Update FOOD_EMOJI, NAME_ALIASES (add + remove bass alias), PROTEIN_KEYS, UNITS (`只`,`罐`), POPULAR_KEYS** (add `菜心|把`, `鲈鱼|条`, `排骨|块` — can replace 3 less-used popular slots or append if UI allows longer; prefer replace last three of current 10).

- [ ] **Step 4: Smoke PASS + Node optional count assert FOOD_DB length increased by 50.**

- [ ] **Step 5: Commit** `Add ~50 Cantonese staple foods to FOOD_DB with nutrition and aliases.`

---

### Task 2: Changelog + acceptance

- [ ] Prepend CHANGELOG section:

```markdown
## 2026-07 — 粤式食材扩库

### 新增 / 变更

- 冰箱目录新增约 50 种粤厨高频食材（菜心、鲈鱼、排骨等）；修正鲈鱼与巴沙别名
```

- [ ] Spec status → `已实施`
- [ ] Commit plan+spec if untracked: `Document Cantonese food expansion.`
- [ ] Manual: search 菜心 / 鲈鱼 / 排骨 in fridge catalog mentally via smoke patterns.

---

## Spec coverage

| Item | Task |
|------|------|
| 50 foods + nutrition | 1 |
| Aliases + fix 鲈鱼 | 1 |
| Emoji / PROTEIN_KEYS / POPULAR | 1 |
| Docs | 2 |

## Placeholder scan

None. Recipes deferred explicitly.

---

## Execution handoff

1. Subagent-Driven (recommended)  
2. Inline  

Which approach?

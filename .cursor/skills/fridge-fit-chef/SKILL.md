---
name: fridge-fit-chef
description: >-
  Maintain 冰箱健身餐助手 — single-file HTML app with localStorage, optional
  Supabase room sync, single-meal recommend engine, adhoc fallback, bulk import.
  Use when editing fridge-fit-chef.html or project docs.
---

# Fridge Fit Chef

## Architecture

- Main UI: `web/fridge-fit-chef.html` (single file, no React/Vue)
- Visual system: **Open Fridge Glow** (`:root` + `html[data-activity]`; sample in `web/design-demo.html`)
- Optional sync: `config/config.js` (copy from `config/config.example.js`) + Supabase CDN
- Room sharing: URL query `?room=<6-char-code>`

## UI notes

- Activity chips → `applyActivityTheme` → `data-activity` (rest / medium / high)
- Meal vs target macros → `macroRingsHtml` / `.macro-rings` (not bars)
- Visual-only changes: keep engine / localStorage / SyncAdapter untouched
- Prefer Noto for dense Chinese text; avoid clipping descenders (line-height + overflow)

## localStorage keys

| Key | Purpose |
|-----|---------|
| ffc_settings | weight, height, age, gender, activityToday |
| ffc_inventory | fridge stock |
| ffc_custom_foods | custom FOOD_DB entries |
| ffc_custom_recipes | custom recipes |
| ffc_exclude_ids | shuffle exclude |
| ffc_stats | recommend_ok, adhoc_used, sync_pulls |

## Engine

- `buildMealPlan()` — single meal, MEAL_RATIO=0.40
- `buildAdHocMeal()` — inventory compose, nutritionRange, isAdHoc
- `getAllFoods()` / `getAllRecipes()` merge custom data

## Bulk import formats

See README.md or openBulkImportSheet in HTML.

## After engine changes

Run `powershell -File tests/smoke.ps1` (or `node tests/smoke.mjs` if Node installed).

## Resume narrative

Update `docs/CHANGELOG-product.md` one line per user-visible feature.

## Constraints

- User text → `escapeHtml()` before innerHTML
- Supabase anon key only in config/config.js (gitignored)
- Sync failure must not wipe local data

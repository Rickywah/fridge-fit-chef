# Fridge Inventory UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix incomplete fridge catalog, put inventory above the add grid with ice-blue styling, and flash the summary when items are added.

**Architecture:** All changes stay in the single-file app `web/fridge-fit-chef.html`. Catalog switches from `POPULAR_KEYS`-only to full `getAllFoods()` (popular keys only for sort). Inventory summary moves above the catalog; add feedback uses `state.justAdded` + CSS pulse. Ice-blue tokens are scoped to `#panel-inventory` only.

**Tech Stack:** Vanilla HTML/CSS/JS (IIFE), localStorage, existing smoke checks in `tests/smoke.ps1`.

**Spec:** [`docs/superpowers/specs/2026-07-24-fridge-inventory-ux-design.md`](../specs/2026-07-24-fridge-inventory-ux-design.md)

## Global Constraints

- Scope: only `#panel-inventory` behavior/theme; do not change meal engine, SyncAdapter, or other tabs’ Open Fridge Glow look.
- Keep `escapeHtml` / `safeText` / `safeAttr` for any user-facing strings in `innerHTML`.
- CTA / just-added accent remains amber `#E8941A`; selected category uses ice `#4A8BB8`.
- Do not commit unless the user explicitly asks (user rule overrides frequent-commit habit in this workspace).
- After UI work: update one line in `docs/CHANGELOG-product.md`; extend `tests/smoke.ps1` with positive checks from this plan.

## File map

| File | Responsibility |
|------|----------------|
| `web/fridge-fit-chef.html` | HTML structure, CSS, `renderFridgePage`, helpers, aliases, state |
| `tests/smoke.ps1` | Static presence checks for new markers |
| `docs/CHANGELOG-product.md` | One user-visible changelog line |

---

### Task 1: Full catalog + 巴沙鱼 alias + search match

**Files:**
- Modify: `web/fridge-fit-chef.html` (`NAME_ALIASES`, replace `getPopularFoods` usage in catalog path, add helpers)
- Modify: `tests/smoke.ps1` (add checks)

**Interfaces:**
- Consumes: `getAllFoods()`, `POPULAR_KEYS`, `state.fridgeCat`, `state.fridgeSearch`, `NAME_ALIASES`
- Produces:
  - `function foodMatchesSearch(foodName, query)` → `boolean`
  - `function getCatalogFoods()` → `Array<{name, unit, grams, cat}>` (filtered + popular-first sort)

- [ ] **Step 1: Extend smoke checks (fail until markers exist)**

In `tests/smoke.ps1`, add to `$checks`:

```powershell
  @{ name = "getCatalogFoods"; pattern = "function getCatalogFoods" },
  @{ name = "foodMatchesSearch"; pattern = "function foodMatchesSearch" },
  @{ name = "basa alias"; pattern = "'巴沙鱼'\s*:\s*'巴沙鱼柳'" },
  @{ name = "add-ingredients heading"; pattern = "添加食材" }
```

- [ ] **Step 2: Run smoke — expect FAIL on new checks**

Run: `powershell -File tests/smoke.ps1`  
Expected: `FAIL: getCatalogFoods` (and related new checks); existing checks still OK.

- [ ] **Step 3: Add alias + helpers**

In `NAME_ALIASES` object, add:

```javascript
'巴沙鱼': '巴沙鱼柳',
```

(keep existing keys; place near `'鲈鱼': '巴沙鱼柳'`).

Add helpers near `getPopularFoods`:

```javascript
function foodMatchesSearch(foodName, query) {
  if (!query) return true;
  var q = String(query).toLowerCase();
  var name = String(foodName || '');
  if (name.toLowerCase().indexOf(q) >= 0) return true;
  var resolved = resolveName(name);
  if (String(resolved).toLowerCase().indexOf(q) >= 0) return true;
  // match when user types alias that maps to this food
  for (var alias in NAME_ALIASES) {
    if (!Object.prototype.hasOwnProperty.call(NAME_ALIASES, alias)) continue;
    if (NAME_ALIASES[alias] === resolved || NAME_ALIASES[alias] === name) {
      if (alias.toLowerCase().indexOf(q) >= 0) return true;
    }
  }
  return false;
}

function getCatalogFoods() {
  var list = getAllFoods().slice();
  if (state.fridgeCat !== '全部') {
    list = list.filter(function (f) { return f.cat === state.fridgeCat; });
  }
  if (state.fridgeSearch) {
    list = list.filter(function (f) { return foodMatchesSearch(f.name, state.fridgeSearch); });
  }
  var popularIndex = {};
  POPULAR_KEYS.forEach(function (key, i) { popularIndex[key] = i; });
  list.sort(function (a, b) {
    var ka = a.name + '|' + a.unit;
    var kb = b.name + '|' + b.unit;
    var ia = popularIndex.hasOwnProperty(ka) ? popularIndex[ka] : 1000;
    var ib = popularIndex.hasOwnProperty(kb) ? popularIndex[kb] : 1000;
    if (ia !== ib) return ia - ib;
    return 0;
  });
  return list;
}
```

- [ ] **Step 4: Wire catalog render to `getCatalogFoods`**

In `renderFridgePage`, replace the block that builds `popular` via `getPopularFoods()` + filters with:

```javascript
var catalog = getCatalogFoods();
$('#popular-grid').innerHTML = catalog.map(function (f) {
  // keep existing card HTML for now (Task 3 adds 已有态)
  var bg = catColor(f.cat);
  return '<div class="popular-card" data-name="' + safeAttr(f.name) + '" data-unit="' + safeAttr(f.unit) + '">' +
    '<div class="food-circle" style="background:' + bg + '">' + safeText(foodEmoji(f.name)) + '</div>' +
    '<div class="food-name">' + safeText(f.name) + '</div>' +
    '<div class="food-unit">' + safeText(f.unit) + ' · ' + f.grams + 'g</div>' +
    '<button class="fab-add" type="button" aria-label="加入' + safeAttr(f.name) + '">+</button></div>';
}).join('') || '<p class="subtitle">无匹配食材</p>';
```

Also change the section heading text in HTML from `常用食材` to `添加食材`.

Keep inventory filter using `foodMatchesSearch(item.name, search)` instead of `indexOf` only.

- [ ] **Step 5: Re-run smoke**

Run: `powershell -File tests/smoke.ps1`  
Expected: `All smoke checks passed.`

- [ ] **Step 6: Manual check**

Open fridge tab → category 水产 → confirm 虾仁、三文鱼、巴沙鱼柳 all visible. Search `巴沙鱼` → 巴沙鱼柳 appears.

---

### Task 2: Inventory-first layout + summary / expand

**Files:**
- Modify: `web/fridge-fit-chef.html` (panel HTML order, CSS for summary, `state.invExpanded`, `renderFridgePage`)

**Interfaces:**
- Consumes: `state.inventory`, `state.fridgeCat`, `state.fridgeSearch`, `foodMatchesSearch`, existing inv list markup patterns
- Produces:
  - `state.invExpanded` (`boolean`, default `false`)
  - DOM: `#inv-summary`, `#btn-inv-expand`, `#inv-grouped` (below summary when expanded)
  - `function getFilteredInventory()` → inventory items matching cat/search
  - `function renderInvSummary(filtered)` → writes summary HTML

- [ ] **Step 1: Add state flag**

In `state` init object:

```javascript
invExpanded: false,
justAdded: null, // { name, unit, at } — used in Task 4; declare now
```

- [ ] **Step 2: Reorder panel HTML**

In `#panel-inventory`, order must be:

1. `.page-header`
2. `.search-bar`
3. `#fridge-cats`
4. Inventory block: `#inv-summary` + `#inv-grouped` + `#inv-empty`
5. Divider (optional)
6. Section head「添加食材」+ `#btn-manual-add`
7. `#popular-grid`

Replace the old inventory section-head + `#inv-grouped` placement. Suggested summary markup:

```html
<div id="inv-summary" class="inv-summary"></div>
<div id="inv-grouped" class="hidden"></div>
<div id="inv-empty" class="empty-state hidden">...</div>
```

Move「填充示例」into the summary header actions (render in JS) or keep a small `#btn-seed-demo` next to expand.

- [ ] **Step 3: Implement filter + summary render**

```javascript
function getFilteredInventory() {
  return state.inventory.filter(function (item) {
    if (!foodMatchesSearch(item.name, state.fridgeSearch)) return false;
    var cat = getFoodCat(item.name, item.unit);
    if (state.fridgeCat !== '全部' && cat !== state.fridgeCat) return false;
    return true;
  });
}

function renderInvSummary(filtered) {
  var el = $('#inv-summary');
  var total = state.inventory.length;
  if (!total) {
    el.innerHTML =
      '<div class="inv-summary-card is-empty">' +
      '<div class="inv-summary-head"><h2>我的库存</h2><span class="badge">0</span></div>' +
      '<p class="subtitle">还是空的 — 从下方添加食材</p>' +
      '<button class="see-all" id="btn-seed-demo" type="button">填充示例</button></div>';
    return;
  }
  var chips = filtered.slice(0, 6);
  var extra = Math.max(0, filtered.length - chips.length);
  // justAdded chip handled in Task 4 — for now plain chips
  var chipsHtml = chips.map(function (item) {
    return '<span class="inv-chip">' + safeText(foodEmoji(item.name) + ' ' + item.name) + '</span>';
  }).join('');
  if (extra > 0) chipsHtml += '<span class="inv-chip inv-chip-more">+' + extra + '</span>';
  var expandLabel = state.invExpanded ? '收起' : '展开全部 ↓';
  el.innerHTML =
    '<div class="inv-summary-card' + (state.justAdded ? ' is-pulse' : '') + '">' +
    '<div class="inv-summary-head"><h2>我的库存</h2><span class="badge" id="inv-count">' + total + '</span></div>' +
    '<div class="inv-chip-row">' + chipsHtml + '</div>' +
    '<div class="inv-summary-actions">' +
    '<button class="see-all" id="btn-inv-expand" type="button">' + expandLabel + '</button>' +
    '<button class="see-all" id="btn-seed-demo" type="button">填充示例</button></div></div>';
}
```

Wire expand button:

```javascript
var exp = $('#btn-inv-expand');
if (exp) {
  exp.addEventListener('click', function () {
    state.invExpanded = !state.invExpanded;
    renderFridgePage();
  });
}
```

In `renderFridgePage`: call `renderInvSummary(getFilteredInventory())`; show `#inv-grouped` only when `state.invExpanded && filtered.length`; reuse existing grouped list HTML builder for expanded content; hide old bottom-only empty that forced scroll past catalog — empty handled in summary.

- [ ] **Step 4: CSS for summary (structural; ice theme in Task 5)**

```css
.inv-summary { margin-bottom: var(--spacing-16); }
.inv-summary-card {
  background: var(--color-paper-white);
  border: 1px solid var(--color-warm-mist);
  border-radius: var(--radius-lg);
  padding: var(--spacing-12) var(--spacing-16);
}
.inv-summary-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: var(--spacing-8); }
.inv-summary-head h2 { margin: 0; font-size: var(--text-subheading); }
.inv-chip-row { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: var(--spacing-8); }
.inv-chip {
  display: inline-flex; align-items: center;
  padding: 4px 10px; border-radius: 999px; font-size: var(--text-caption);
  background: var(--color-soft-linen); border: 1px solid var(--color-warm-mist);
}
.inv-summary-actions { display: flex; justify-content: space-between; gap: 8px; }
#inv-grouped.hidden { display: none; }
```

Re-bind `#btn-seed-demo` after each summary render (same handler as today).

- [ ] **Step 5: Manual check**

Fridge tab first screen shows inventory summary without scrolling past catalog. Expand shows 改/删 list; collapse hides it.

---

### Task 3: Catalog「已有」vs「+」states

**Files:**
- Modify: `web/fridge-fit-chef.html` (`renderFridgePage` card HTML + CSS)

**Interfaces:**
- Consumes: `state.inventory`, `resolveName`
- Produces: `function inventoryQtyFor(name, unit)` → `number` (0 if absent)

- [ ] **Step 1: Helper**

```javascript
function inventoryQtyFor(name, unit) {
  name = resolveName(name);
  var item = state.inventory.find(function (i) {
    return resolveName(i.name) === name && i.unit === unit;
  });
  return item ? item.quantity : 0;
}
```

- [ ] **Step 2: Card markup**

When mapping catalog cards:

```javascript
var qty = inventoryQtyFor(f.name, f.unit);
var owned = qty > 0;
var action = owned
  ? '<div class="owned-badge">已有 · ' + qty + safeText(f.unit) + '</div>'
  : '<button class="fab-add" type="button" aria-label="加入' + safeAttr(f.name) + '">+</button>';
return '<div class="popular-card' + (owned ? ' is-owned' : '') + '" data-name="..." data-unit="...">' +
  /* circle, name, unit */ + action + '</div>';
```

Click handlers: whole card still opens `openQuickAddSheet` (owned = add more). If `.fab-add` missing, still bind card click.

- [ ] **Step 3: CSS**

```css
.popular-card.is-owned { border-color: rgba(74, 139, 184, 0.45); }
.owned-badge {
  display: inline-block; margin-top: 6px;
  padding: 2px 8px; border-radius: 999px;
  font-size: 11px; font-weight: 600;
  background: rgba(74, 139, 184, 0.16); color: #2A6A8A;
}
```

- [ ] **Step 4: Manual check**

Add 虾仁 → card shows「已有 · N把」; 巴沙鱼柳 still shows +.

---

### Task 4: Just-added pulse feedback

**Files:**
- Modify: `web/fridge-fit-chef.html` (`addToInventory` callers / wrapper, summary chips, CSS animation)

**Interfaces:**
- Consumes: `state.justAdded`
- Produces: `function markJustAdded(name, unit)` sets state + timeouts; clears `is-pulse` after 1200ms and `justAdded` after 2000ms

- [ ] **Step 1: markJustAdded**

```javascript
var justAddedPulseTimer = null;
var justAddedClearTimer = null;
function markJustAdded(name, unit) {
  state.justAdded = { name: resolveName(name), unit: unit, at: Date.now() };
  clearTimeout(justAddedPulseTimer);
  clearTimeout(justAddedClearTimer);
  justAddedPulseTimer = setTimeout(function () {
    var card = document.querySelector('.inv-summary-card');
    if (card) card.classList.remove('is-pulse');
  }, 1200);
  justAddedClearTimer = setTimeout(function () {
    state.justAdded = null;
    if (state.activeTab === 'inventory') renderFridgePage();
  }, 2000);
}
```

Call `markJustAdded(name, unit)` inside `addToInventory` after successful push/update (before `return true`).

- [ ] **Step 2: Summary chip priority**

In `renderInvSummary`, if `state.justAdded`, prepend:

```javascript
'<span class="inv-chip inv-chip-just">' +
  safeText(foodEmoji(state.justAdded.name) + ' ' + state.justAdded.name) +
  ' ·刚加</span>'
```

Then fill remaining chip slots from `filtered` excluding that name+unit, up to 6 total chips.

- [ ] **Step 3: Pulse CSS**

```css
.inv-summary-card.is-pulse {
  border-color: #E8941A;
  box-shadow: 0 0 0 3px rgba(232, 148, 26, 0.22);
  transition: box-shadow 0.2s, border-color 0.2s;
}
.inv-chip-just {
  background: #E8941A;
  color: #1A2330;
  font-weight: 700;
  border-color: transparent;
}
@media (prefers-reduced-motion: reduce) {
  .inv-summary-card.is-pulse { box-shadow: none; }
}
```

- [ ] **Step 4: Manual check**

Add 巴沙鱼柳 → toast + summary pulses +「刚加」chip + badge increments + catalog「已有」. After ~2s chip returns to normal preview.

---

### Task 5: Ice-blue theme scoped to fridge panel

**Files:**
- Modify: `web/fridge-fit-chef.html` (CSS under `#panel-inventory`)

**Interfaces:**
- Consumes: none (CSS only)
- Produces: visual tokens scoped to `#panel-inventory` / `#panel-inventory.active`

- [ ] **Step 1: Scoped overrides**

```css
#panel-inventory.active {
  background: linear-gradient(180deg, #E4ECF2 0%, #EEF3F7 100%);
  color: #1A2330;
}
#panel-inventory .inv-summary-card {
  background: linear-gradient(165deg, rgba(255,255,255,.95), rgba(220,236,246,.9));
  border-color: rgba(120, 170, 200, 0.35);
}
#panel-inventory .popular-card,
#panel-inventory .search-bar,
#panel-inventory .inv-card {
  background: rgba(255, 255, 255, 0.88);
  border-color: rgba(120, 170, 200, 0.22);
}
#panel-inventory .cat-chip.active {
  border-color: #4A8BB8;
  color: #1A2330;
  background: rgba(70, 140, 190, 0.14);
}
#panel-inventory .food-circle {
  background: linear-gradient(180deg, #E8F3FA, #D4E6F2);
  border-color: rgba(120, 170, 200, 0.2);
}
#panel-inventory .see-all { color: #E8941A; }
#panel-inventory .fab-add { background: #E8941A; color: #1A2330; }
```

Ensure tab bar / other panels unchanged (no `:root` ice overrides).

- [ ] **Step 2: Manual check**

Switch Today ↔ Fridge ↔ Recipes: only Fridge shows ice shell; Today still porcelain/shell Open Fridge Glow.

- [ ] **Step 3: Smoke + changelog**

Add smoke check:

```powershell
  @{ name = "fridge ice panel"; pattern = "#panel-inventory\.active" }
```

Append to `docs/CHANGELOG-product.md`:

```markdown
- 冰箱页：完整食材目录、库存置顶摘要、加入高亮反馈、冰蓝霜感（仅冰箱 Tab）
```

Run: `powershell -File tests/smoke.ps1` → all pass.

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| Full `getAllFoods` catalog | 1 |
| Popular-first sort | 1 |
| 巴沙鱼 alias + search | 1 |
| 「添加食材」copy | 1 |
| Inventory above catalog | 2 |
| Collapse / expand | 2 |
| 已有 vs + | 3 |
| Pulse + 刚加 chip + badge | 4 |
| Ice theme fridge-only | 5 |
| No engine/sync/other-tab theme | Global + Task 5 |
| Smoke + changelog | 1, 5 |

## Placeholder scan

No TBD / “implement later” steps. Commit steps omitted per workspace user rule (ask user before `git commit`).

---

## Execution handoff

Plan saved to `docs/superpowers/plans/2026-07-24-fridge-inventory-ux.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — run tasks in this session with executing-plans checkpoints  

Which approach?

# Smoke checks for web/fridge-fit-chef.html (no Node required)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$html = Join-Path $root "web\fridge-fit-chef.html"
if (-not (Test-Path $html)) { Write-Error "Missing web/fridge-fit-chef.html"; exit 1 }
$content = Get-Content $html -Raw -Encoding UTF8
$checks = @(
  @{ name = "buildMealPlan"; pattern = "function buildMealPlan" },
  @{ name = "buildAdHocMeal"; pattern = "function buildAdHocMeal" },
  @{ name = "parseBulkFoods"; pattern = "function parseBulkFoods" },
  @{ name = "escapeHtml"; pattern = "function escapeHtml" },
  @{ name = "SyncAdapter"; pattern = "var SyncAdapter" },
  @{ name = "exportAllData"; pattern = "function exportAllData" },
  @{ name = "importAllData"; pattern = "function importAllData" },
  @{ name = "share-url"; pattern = 'id="share-url"' },
  @{ name = "room-code"; pattern = 'id="room-code"' },
  @{ name = "exportFridgeShare"; pattern = "function exportFridgeShare" },
  @{ name = "btn-recommend"; pattern = "btn-recommend" },
  @{ name = "CAT_META"; pattern = "var CAT_META" },
  @{ name = "VEG_CATS"; pattern = "var VEG_CATS" },
  @{ name = "shop-item-icon"; pattern = "shop-item-icon" },
  @{ name = "isVegCat"; pattern = "function isVegCat" },
  @{ name = "warm bg pattern"; pattern = "--bg-pattern" },
  @{ name = "config path"; pattern = '\.\./config/config\.js' },
  @{ name = "reduced motion"; pattern = "prefers-reduced-motion" },
  @{ name = "tablist semantics"; pattern = 'role="tablist"' },
  @{ name = "sheet dialog semantics"; pattern = 'aria-modal="true"' },
  @{ name = "getCatalogFoods"; pattern = "function getCatalogFoods" },
  @{ name = "foodMatchesSearch"; pattern = "function foodMatchesSearch" },
  @{ name = "basa alias"; pattern = "'巴沙鱼'\s*:\s*'巴沙鱼柳'" },
  @{ name = "add-ingredients heading"; pattern = "添加食材" },
  @{ name = "fridge ice panel"; pattern = "#panel-inventory\.active" },
  @{ name = "shop-tray"; pattern = "shop-tray" },
  @{ name = "shopCart state"; pattern = "shopCart" },
  @{ name = "nutrition100 field"; pattern = "nutrition100" },
  @{ name = "nutrition data version"; pattern = "NUTRITION_DATA_VERSION" },
  @{ name = "skinned chicken leg"; pattern = "带皮鸡腿肉" },
  @{ name = "fatty beef"; pattern = "肥牛片" },
  @{ name = "getFoodNutrition100"; pattern = "function getFoodNutrition100" },
  @{ name = "calcRecipeNutrition scale"; pattern = "function calcRecipeNutrition\(recipe,\s*scale\)" },
  @{ name = "estimated badge"; pattern = "含估算项" },
  @{ name = "custom food p100 input"; pattern = "cf-p100" },
  @{ name = "servingScale state"; pattern = "servingScale" },
  @{ name = "servingScale chips helper"; pattern = "function servingScaleChipsHtml" },
  @{ name = "scaled deduct"; pattern = "function deductInventoryFromPlan\(meals,\s*scale\)" },
  @{ name = "scale warn copy"; pattern = "当前份量库存不足" },
  @{ name = "nutrition disclaimer"; pattern = "营养为饮食规划估算，非医疗用途" },
  @{ name = "calcBmr"; pattern = "function calcBmr" },
  @{ name = "calcTdee"; pattern = "function calcTdee" },
  @{ name = "GOAL_META"; pattern = "var GOAL_META" },
  @{ name = "goal cut ratio"; pattern = "cut:\s*\{[^}]*ratio:\s*0\.8" },
  @{ name = "goal chips"; pattern = 'id="goal-chips"' },
  @{ name = "data-goal cut"; pattern = 'data-goal="cut"' },
  @{ name = "hero goal copy"; pattern = "目标 · 今日约" }
)
$failed = 0
foreach ($c in $checks) {
  if ($content -notmatch $c.pattern) {
    Write-Host "FAIL: $($c.name)"
    $failed++
  } else {
    Write-Host "OK: $($c.name)"
  }
}
$negativeChecks = @(
  @{ name = "no disabled zoom"; pattern = "user-scalable=no" },
  @{ name = "no gradient clipped headings"; pattern = "background-clip:\s*text" },
  @{ name = "no meal side stripe"; pattern = "border-left:\s*4px\s+solid\s+var\(--accent\)" },
  @{ name = "localized fridge section"; pattern = ">Popular<" }
)
foreach ($c in $negativeChecks) {
  if ($content -match $c.pattern) {
    Write-Host "FAIL: $($c.name)"
    $failed++
  } else {
    Write-Host "OK: $($c.name)"
  }
}
if ($failed -gt 0) { exit 1 }
Write-Host "All smoke checks passed."
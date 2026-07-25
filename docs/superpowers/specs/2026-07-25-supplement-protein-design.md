# 蛋白粉补剂专区（今日已喝扣减这顿蛋白）

**日期：** 2026-07-25  
**状态：** 已实施  
**范围：** 蛋白粉预设与自定义、今日「已喝」日志、从「这顿」蛋白目标中扣减  
**不做：** 肌酸等不计宏量的补剂、补剂进冰箱库存、改 TDEE/营养库/份量缩放、多餐分摊  
**主文件：** [`web/fridge-fit-chef.html`](../../../web/fridge-fit-chef.html)

---

## 问题

训练后冲蛋白粉（约 21g 蛋白）已计入当日蛋白，但推荐仍按日目标 ×40% 要饭里的蛋白，导致「这顿」蛋白偏高。

---

## 已确认决策

| 项 | 选择 |
|----|------|
| 触发 | 今日点「已喝」才扣（非日程默认扣） |
| 数据 | 内置乳清 + 可改每份克数 + 可自定义蛋白粉 |
| 扣减 | 只扣这顿蛋白；C/F 仍日×40% |
| 品类 | 首版仅蛋白粉；不做肌酸等 |

---

## 数据模型

### 内置 + 用户预设（持久化）

```javascript
// 内置种子（不可删 id；可改 servings 默认与每份宏量）
SUPPLEMENT_SEED = [{
  id: 'whey-default',
  name: '乳清蛋白粉',
  kind: 'protein_powder',
  proteinPerServing: 21,
  carbPerServing: 0,
  fatPerServing: 0,
  defaultServings: 1
}]

// localStorage: custom protein powders + overrides of seed
state.supplements = [
  // { id, name, kind:'protein_powder', proteinPerServing, carbPerServing?, fatPerServing?, isCustom? }
]
```

`loadState`：若无用户数据，用 `SUPPLEMENT_SEED` 初始化到 `state.supplements`（或合并：种子始终存在，用户覆盖同 id 的数值）。

### 今日摄入日志

```javascript
// localStorage key e.g. ffc_supplement_log
{
  date: '2026-07-25',  // 本地日历日 YYYY-MM-DD
  intakes: [
    { id: 'whey-default', servings: 1 }
  ]
}
```

- 打开/读写时若 `date !== today` → 重置为 `{ date: today, intakes: [] }`
- `servings` 允许 0.5 步进；`0` 表示未喝（可从 intakes 移除）

---

## 计算

```
daily = calcDailyTargets(settings)
baseMeal = mealTargets(daily, MEAL_RATIO)  // 现有 0.40，含 P/C/F
suppP = sum( intakes.servings × proteinPerServing for today's intakes )
mealProtein = max(0, baseMeal.protein − round(suppP) )
mealTargetsEffective = {
  protein: mealProtein,
  carb: baseMeal.carb,
  fat: baseMeal.fat,
  kcal: mealProtein*4 + baseMeal.carb*4 + baseMeal.fat*9,
  supplementProtein: round(suppP)
}
```

- `buildMealPlan` / `buildAdHocMeal` / 推荐结果圆环与 gap tips 一律使用 **effective** 这顿目标  
- 日目标展示（今天英雄区日宏量）**不变**；另显示「已计补剂蛋白 −XXg」  
- 若 `suppP` 大于基础这顿蛋白：这顿蛋白目标为 0，不出现负值；推荐仍可出餐（蛋白评分会偏低，可接受）

---

## UI

### 今天页（训练状态卡下方）

新卡片「蛋白粉」：

- 列出 `state.supplements` 每一项：名称、每份 Pg、`−` / 份数 / `+`（或「已喝」切换 + 份数）  
- 底部汇总：`今日补剂蛋白合计 XXg · 这顿蛋白目标已扣`  
- 改份数立即 `saveSupplementLog` + 若已有推荐结果则用新目标重渲（不强制重新洗牌菜谱；圆环/tips 更新；已生成结果可提示「目标已变，可重新生成」——首版：**重渲圆环与文案即可，不自动 reshuffle**）

### 「我的」

「蛋白粉」小节（身体目标附近）：

- 编辑内置项每份 P（及可选 C/F）  
- 添加/删除自定义蛋白粉  
- 不提供肌酸等入口

### 推荐结果

- 本餐 vs 目标使用扣减后蛋白  
- 若 `supplementProtein > 0`，日总计旁或 gap 区一行：`已计入蛋白粉 −XXg`

---

## 代码改动点

| 区域 | 改动 |
|------|------|
| `STORAGE_KEYS` | `supplements`, `supplementLog` |
| 常量 / state | `SUPPLEMENT_SEED`, `state.supplements`, log helpers |
| `getTodaySupplementProtein()` | 汇总今日蛋白 |
| `mealTargetsForRecommend()` | 或扩展 `mealTargets` 调用点使用 effective |
| `buildMealPlan` / `buildAdHocMeal` | 改用 effective 目标 |
| 今天页 HTML + `renderSupplementCard` | 新卡 |
| 「我的」管理 UI | 编辑预设 |
| smoke / CHANGELOG | 标记与用户说明 |

---

## 非目标

- 肌酸、BCAA、咖啡因等  
- 补剂与冰箱库存打通  
- 从日目标直接减蛋白再 ×40%  
- 同步到 Supabase（本地即可；若 export/import 已有框架则顺带纳入，非必须）

---

## 验收标准

1. 未记录已喝时，这顿蛋白 = 日×40%（与改前一致）。  
2. 已喝 1 份默认乳清（21g）后，这顿蛋白目标减少约 21g。  
3. 改每份蛋白克数后，扣减跟新值。  
4. 日期变更后 intakes 清空，扣减消失。  
5. 自定义蛋白粉可添加并参与扣减。  
6. C/F 这顿目标不因蛋白粉改变（除非用户给粉填了 C/F——首版 **仅扣 P**，自定义的 C/F 仅展示、不扣这顿 C/F，避免范围膨胀）。  
7. `tests/smoke.ps1` 通过。

---

## 示例

日蛋白 154g → 这顿基础 62g；已喝 21g → 这顿蛋白目标 **41g**；碳水/脂肪仍为日×40%。

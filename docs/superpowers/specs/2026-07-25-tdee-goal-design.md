# TDEE + 减脂/维持/增肌目标

**日期：** 2026-07-25  
**状态：** 已实施  
**范围：** BMR/TDEE、周期目标（减脂/维持/增肌）、与今日训练状态联动的日宏量；设置与今天页展示  
**不做：** 体脂率、自定义缺口滑条、周计划日历、自动蛋白替换、改营养库/份量逻辑  
**主文件：** [`web/fridge-fit-chef.html`](../../../web/fridge-fit-chef.html)  
**前置：** 营养库子项目 A 已合并（`calcDailyTargets` 仍为旧 g/kg 直算）

---

## 问题

当前日目标仅用 `MACRO_RATIOS[activityToday]` × 体重得到 P/C/F，热量用 4/4/9 反推，**未使用**已采集的身高/年龄/性别，也没有减脂缺口或增肌盈余。同体重「减脂」与「增肌」无法区分。

---

## 已确认决策

| 项 | 选择 |
|----|------|
| 周期目标位置 | 「我的」设置：减脂 / 维持 / 增肌 |
| 今日训练状态 | 保留今天页三档；影响 TDEE 活动系数 |
| 目标热量 | 相对 TDEE 固定比例：×0.8 / ×1.0 / ×1.1 |
| 训练日进公式 | 改 TDEE 系数（非仅改宏量） |
| 宏量拆分 | 蛋白优先 g/kg → 脂肪 0.9 g/kg → 剩余给碳水 |
| BMR | Mifflin–St Jeor |
| 这顿占比 | 仍 `MEAL_RATIO = 0.40` |

---

## 设置模型

```javascript
settings: {
  weight, height, age, gender,      // 已有
  activityToday: 'rest'|'medium'|'high',  // 已有
  goal: 'cut'|'maintain'|'bulk'     // 新增，默认 maintain
}
```

旧 localStorage 无 `goal` → 视为 `'maintain'`。

---

## 计算

### BMR（Mifflin–St Jeor）

- 男：`10×weight + 6.25×height − 5×age + 5`
- 女：`10×weight + 6.25×height − 5×age − 161`
- 结果四舍五入为整数 kcal

### TDEE

| activityToday | 系数 | 标签 |
|---------------|------|------|
| rest | 1.375 | 休息日 |
| medium | 1.55 | 常规训练 |
| high | 1.725 | 高强度 |

`TDEE = round(BMR × factor)`

### 日目标热量

| goal | 比例 | 文案 |
|------|------|------|
| cut | 0.80 | 减脂 |
| maintain | 1.00 | 维持 |
| bulk | 1.10 | 增肌 |

`targetKcal = max(round(TDEE × ratio), round(BMR × 1.1))`

### 宏量（蛋白优先）

蛋白 g/kg：

| goal \ activity | rest | medium | high |
|-----------------|------|--------|------|
| cut | 2.0 | 2.2 | 2.4 |
| maintain | 1.85 | 2.0 | 2.2 |
| bulk | 1.85 | 2.0 | 2.2 |

1. `protein = round(weight × proteinPerKg)`
2. `fat = round(weight × 0.9)`
3. `carbKcal = targetKcal − protein×4 − fat×9`
4. `carb = round(carbKcal / 4)`
5. 若 `carb < round(weight × 2)`：将脂肪改为 `round(weight × 0.7)`，重算碳水一次
6. 若仍不足：碳水取 `round(weight × 2)`，接受展示热量 `P×4+C×4+F×9` 可能略高于 `targetKcal`
7. 对外 `kcal` 一律用 `P×4+C×4+F×9`（与宏量圆环一致）

### `calcDailyTargets(s)` 返回（扩展）

```javascript
{
  protein, carb, fat, kcal,
  bmr, tdee, targetKcal,   // targetKcal 为热量预算；kcal 为宏量求和
  goal, goalLabel,
  activityToday, label, emoji,  // 训练日标签（沿用 MACRO_RATIOS 文案或 GOAL/ACTIVITY 元数据）
  ratios: { protein, fat, carb } // g/kg 实际采用值，供 formatTargets
}
```

推荐引擎、圆环、今天英雄区全部改走新返回值；不再用旧「先定 g/kg 再反推 kcal」作为主路径。

---

## UI

### 「我的」

- 「周期目标」三芯片：减脂 / 维持 / 增肌（样式复用 `.chip` / `.chip.active`）
- 保存时写入 `settings.goal`
- `#targets-settings` 展示链路，例如：  
  `减脂 · 常规训练日 · BMR 1650 · TDEE 2560 · 目标 2050 kcal · P 154g · C …g · F …g`
- 保留免责：饮食规划估算，非医疗用途

### 今天页

- 训练状态三档与主题切换不变
- 英雄区增加一行：`{goalLabel}目标 · 今日约 {kcal} kcal`（不强制展示 BMR）

### 推荐结果

- 仍对比「这顿」与 `mealTargets(daily, 0.40)`；无新控件

---

## 代码改动点

| 区域 | 改动 |
|------|------|
| 常量 | `GOAL_META`、`ACTIVITY_FACTOR`、`PROTEIN_PER_KG[goal][activity]`；`MACRO_RATIOS` 可降级为仅提供 label/emoji，或内联到 ACTIVITY 元数据 |
| `calcBmr` / `calcTdee` / `calcDailyTargets` / `formatTargets` | 新实现 |
| `loadState` 默认 settings | 加 `goal: 'maintain'` |
| 设置表单 HTML + `renderSettingsForm` + 保存 | 目标芯片 |
| `renderTodayHero` | 展示目标 + 今日热量 |
| `tests/smoke.ps1` | `calcBmr`、`goal`、目标文案等 |
| `docs/CHANGELOG-product.md` | 一行用户可见说明 |

---

## 非目标

- 体脂率、LBM 公式
- 用户自定义缺口百分比滑条
- 按星期排训练的周视图
- 子项目 C（蛋白替换匹配）
- 修改营养库、份量缩放、扣库存逻辑

---

## 验收标准

1. 同人同训练日：减脂日目标热量 &lt; 维持 &lt; 增肌。  
2. 同人同目标：高强度日 TDEE/目标热量 &gt; 休息日。  
3. 减脂日蛋白 g/kg ≥ 同训练档维持日。  
4. 无 `goal` 的旧设置加载后等价维持，页面不报错。  
5. 生成推荐后，圆环目标来自新 `calcDailyTargets`。  
6. 设置区可见 BMR / TDEE / 目标热量链路。  
7. `tests/smoke.ps1` 通过。

---

## 示例（验算用，实现时以代码为准）

男 70kg / 175cm / 30 岁 / 常规训练 / 减脂：

- BMR ≈ `10×70 + 6.25×175 − 5×30 + 5` = 1649 → **1649**
- TDEE ≈ `1649 × 1.55` → **2556**
- 目标热量 ≈ `2556 × 0.8` = 2045；下限 `1649×1.1`≈1814 → **2045**
- 蛋白 `70×2.2` = **154g**；脂肪 `70×0.9` = **63g**  
- 碳水 kcal = `2045 − 154×4 − 63×9` = 862 → 碳水 **216g**（`Math.round(862/4)`）  
- 展示 kcal = `154×4 + 216×4 + 63×9` = **2049**（宏量求和；`targetKcal` 仍为 2045）

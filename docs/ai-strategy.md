# AI / 智能策略

## 设计原则

Fridge Fit Chef 采用 **「规则优先、Agent 兜底」** 分层，而非端到端 LLM，以保证：

- 离线可用、零 API 成本
- 推荐结果可解释、可复现
- Portfolio 可讲述「AI PM 如何设计 hybrid 系统」

## Layer 1：规则推荐引擎

**入口**：`buildMealPlan(excludeIds, shuffle)`

1. 根据 settings 计算日目标 → 单餐目标（40%）
2. 过滤库存不足、exclude 已看过的 recipe combo
3. 评分：宏量接近度 + 库存利用率 + 多样性
4. 输出：结构化菜谱步骤、精确 P/C/F、缺口提示

**适用**：库存与内置/自定义菜谱能组成合理一餐。

## Layer 2：Adhoc Fallback（「新的尝试」）

**入口**：`buildAdHocMeal(randomize, excludeIds)`

当 Layer 1 失败或无匹配时：

1. 从库存按类别（蛋白/碳水/蔬菜/脂肪）抽样组合
2. 生成简化步骤模板（`adhocStepsForCat`）
3. 输出 **营养区间**（±15%）而非点估计
4. UI 展示 disclaimer：临时组合、仅供参考

**Portfolio 叙事**：这是「轻量 agent」占位——未来可替换为 LLM 生成步骤与名称，接口已预留（`adhocRecipe`、存为菜谱）。

## Layer 3：协作与记忆（非 generative）

- **Supabase room**：跨设备共享「世界状态」（库存）
- **localStorage stats**：`recommend_ok`, `adhoc_used`, `sync_pulls`
- **JSON 备份**：用户可控的数据 portability

## 未来 LLM 集成点（未实现）

见 [`prompts/meal-suggest-v1.md`](../prompts/meal-suggest-v1.md)：

- 输入：库存 JSON + 宏量目标 + 忌口
- 输出：严格 JSON schema 的单餐方案
- 失败时回退 Layer 2

## 与 AI PM JD 的对齐

| JD 能力 | 本项目体现 |
|---------|------------|
| 定义 AI 产品边界 | 规则 vs LLM fallback 分层 |
| 评估与指标 | stats + 成功率/兜底率可观测 |
| 数据飞轮 | 自定义菜谱、adhoc 存为菜谱 |
| 跨端协作 | Supabase sync + 分享链接 |

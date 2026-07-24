# 产品变更日志

## 2026-07 — 冰箱库存 UX

### 新增 / 变更

- 冰箱页：完整食材目录、库存置顶摘要、加入高亮反馈、冰蓝霜感（仅冰箱 Tab）

## 2026-07 — Open Fridge Glow 视觉

### 新增 / 变更

- 主应用并入 **Open Fridge Glow**：瓷白壳灰底、琥珀 CTA、Syne + Noto Sans SC
- 训练状态三套页面主题（休息 / 常规 / 高强度），CTA 与底色随 `data-activity` 切换
- 推荐结果「本餐 vs 目标」改为 **P/C/F 宏量圆环**（替代进度条）
- 今天页品牌标题（Fridge Fit Chef / 冰箱健身餐）；列表文案防字脚裁切
- 视觉样板：`web/design-demo.html`（不改引擎）

## 2026-07 — v2 + 协作同步

### 新增

- 四 Tab 移动端 UI（今天 / 冰箱 / 菜谱 / 我的）
- **单餐**推荐（约 40% 日宏量），按钮「生成这顿」
- **新的尝试**：无菜谱匹配时的 adhoc 组合 + 营养区间
- 自定义食材/菜谱 CRUD，批量导入
- **共享冰箱**：`?room=` + Supabase 同步与 Realtime
- 使用统计、JSON 导入导出
- `escapeHtml` 防止自定义名称 XSS
- 项目 Cursor skill / rules / smoke hooks
- Portfolio 文档（PRD、架构、AI 策略、指标）

### 变更

- 从「全日多餐计划」收敛为「这一顿」决策，降低认知负担

### 已知限制

- Supabase RLS 为 demo 级公开读写
- 冲突合并为 last-write-wins
- Adhoc 为本地规则，非真实 LLM


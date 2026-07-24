# 指标与观测

## 本地指标（localStorage `ffc_stats`）

| 键 | 触发时机 | 用途 |
|----|----------|------|
| `recommend_ok` | 「生成这顿」成功 | 主路径转化率 |
| `adhoc_used` | 「新的尝试」成功 / adhoc 换一套成功 | Fallback 依赖度 |
| `sync_pulls` | 从 Supabase 应用远程数据 | 协作活跃度 |

展示位置：**我的 → 使用统计**

## 建议派生指标

```
adhoc_rate = adhoc_used / (recommend_ok + adhoc_used)
sync_engagement = sync_pulls per room per week
```

## 未来（需后端）

- 推荐失败原因分布（库存空 / 无匹配 / 宏量无法满足）
- Room 活跃用户数、push 失败率
- 「标记完成」→ 实际扣减成功率

## 实验假设（可写进 PRD 复盘）

1. 单餐比全日计划提高「生成这顿」点击率
2. 共享链接降低「库存不准」导致的推荐失败
3. Adhoc 区间展示比假精确数字更可信

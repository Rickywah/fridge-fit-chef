# 应用入口

| 文件 | 说明 |
|------|------|
| [fridge-fit-chef.html](fridge-fit-chef.html) | 主应用，双击打开 |
| [index.html](index.html) | 跳转至主应用（保留 URL 参数） |
| [design-demo.html](design-demo.html) | Open Fridge Glow 视觉样板（Today + 冰箱 mock） |

配置见上级 [`config/`](../config/) 目录。

## 视觉约定

- 设计系统名：**Open Fridge Glow**（token 在主文件 `:root` / `html[data-activity]`）
- 训练状态切换会改页面底色与 CTA，由 `applyActivityTheme()` 写 `data-activity`
- 推荐结果宏量用 `.macro-rings`；列表 meta 注意行高，避免字脚裁切
- 改 UI 保持单文件；不要为此引入 React/Vue

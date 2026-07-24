# Fridge Fit Chef

单文件移动端 Web 应用：根据冰箱库存、健身目标推荐**这一顿**吃什么，支持家人通过链接共享同一冰箱。

## 项目结构

```
Fridge Fit Chef/
├── web/                    ← 应用（HTML，打开这里）
│   ├── index.html
│   ├── fridge-fit-chef.html   主应用
│   └── design-demo.html       Open Fridge Glow 视觉样板（可选）
├── config/                 ← 配置文件
│   ├── config.example.js
│   └── config.js           （本地，已 gitignore）
├── docs/                   产品文档
├── supabase/               数据库迁移
├── scripts/                打包 / 部署脚本
├── tests/                  冒烟测试
└── README.md
```

## 快速开始

1. **双击打开** [`web/fridge-fit-chef.html`](web/fridge-fit-chef.html)（或根目录 [`index.html`](index.html) 会自动跳转）。
2. 在「冰箱」页添加库存，在「我的」设置体重/身高/活动量。
3. 回到「今天」点击 **生成这顿**；推荐结果用 **P/C/F 宏量圆环**对照本餐目标。

## 视觉（Open Fridge Glow）

主应用采用 **Open Fridge Glow** 视觉系统（已并入主 HTML，不依赖框架）：

| 项 | 说明 |
|----|------|
| 字体 | Syne（品牌英文）+ Noto Sans SC（中文 UI） |
| 主色 | 瓷白 / 壳灰底 + 琥珀 CTA；蛋白 / 碳水 / 脂肪分色 |
| 训练主题 | 休息日冷灰蓝、常规训练琥珀、高强度焰橙（`html[data-activity]`） |
| 签名组件 | 本餐 vs 目标的 P/C/F 圆环进度 |

静态样板见 [`web/design-demo.html`](web/design-demo.html)。改视觉时优先对齐该样板与主文件中的 CSS 变量，勿改推荐引擎逻辑。

## 共享冰箱（Supabase）

同一房间码 = 同一库存，适合你和家人各用手机维护同一冰箱。

### 1. 创建 Supabase 项目

1. 登录 [supabase.com](https://supabase.com) 新建项目。
2. 在 **SQL Editor** 运行 [`supabase/migrations/001_fridge_room.sql`](supabase/migrations/001_fridge_room.sql)。
3. 在 **Database → Replication** 为 `fridge_data` 表开启 Realtime。

### 2. 配置前端

```powershell
copy config\config.example.js config\config.js
```

编辑 `config/config.js`，填入项目的 URL 与 anon key（Settings → API）。

> `config/config.js` 已在 `.gitignore` 中，勿提交真实密钥。

### 3. 分享给家人

- **房间码**：我的 → 复制分享 → 微信发给家人
- **发 zip**：运行 `scripts\make-share-pack.ps1`，发送 `dist\Fridge-Fit-Chef-share.zip`

## 部署（GitHub Pages）

1. 将仓库推送到 GitHub。
2. Settings → Pages → 发布目录选 **`/web`**（或上传 `dist/deploy.zip` 到 Netlify）。
3. 若用 GitHub Pages 且需 Supabase，将 `config/config.js` 复制为 `web/config.js` 并改 HTML 引用为 `config.js`（分享包脚本已自动处理扁平布局）。

本地校验：`tests\smoke.ps1`

## 文档

- [PRD](docs/PRD.md) · [架构](docs/architecture.md) · [AI 策略](docs/ai-strategy.md)

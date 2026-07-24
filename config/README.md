# 配置

复制模板并填写 Supabase 凭证：

```powershell
copy config.example.js config.js
```

`config.js` 已被 git 忽略，勿提交真实密钥。

应用通过 `web/fridge-fit-chef.html` 中的 `<script src="../config/config.js">` 加载配置。

# GitHub 自动同步配置说明

## 📋 概述

`auto-sync-github.sh` 是一个自动化脚本，用于检测本地更改并推送到 GitHub 仓库。

## 🔧 配置步骤

### 1. 首次设置认证

由于使用 HTTPS URL 推送到 GitHub，需要配置认证方式：

#### 方式 A: 使用 GitHub Personal Access Token (推荐)

```bash
# 1. 创建 Personal Access Token
# 访问: https://github.com/settings/tokens
# 选择: repo (full control of private repositories)
# 复制生成的 token

# 2. 在仓库中配置凭据（使用 git credential helper）
cd /workspace/jiedian
git config credential.helper store

# 3. 推送时输入用户名和 token
git push origin main --force
# Username: sofian9aadmg3hod49pc-lgtm
# Password: <粘贴你的 token>
```

#### 方式 B: 配置 SSH URL（更安全）

```bash
# 1. 生成 SSH 密钥（如果还没有）
ssh-keygen -t ed25519 -C "sofian9aadmg3hod49pc@gmail.com"

# 2. 复制公钥内容
cat ~/.ssh/id_ed25519.pub

# 3. 添加到 GitHub
# 访问: https://github.com/settings/ssh/new
# 粘贴公钥

# 4. 切换远程 URL 为 SSH
cd /workspace/jiedian
git remote set-url origin git@github.com:sofian9aadmg3hod49pc-lgtm/jiedian.git

# 5. 测试连接
ssh -T git@github.com
```

### 2. 使用自动同步脚本

```bash
# 查看当前状态
./auto-sync-github.sh status

# 完整同步（添加、提交、推送）
./auto-sync-github.sh sync

# 仅推送已有提交
./auto-sync-github.sh push

# 强制推送（覆盖远程）
./auto-sync-github.sh force
```

## 📊 当前状态

| 项目 | 状态 |
|------|------|
| 本地提交数 | 6 |
| 远程提交数 | 1 (需要更新) |
| 本地文件数 | 27 |
| 待推送文件 | 27 |

## 🔍 问题排查

### 问题: 推送超时或认证失败

**解决方案:**

```bash
# 1. 检查远程 URL
git remote -v

# 2. 测试 GitHub 连接
curl -I https://github.com

# 3. 配置凭据
git config credential.helper store
git push origin main --force
# 输入用户名和 token
```

### 问题: 强制推送后远程未更新

**可能原因:**
1. 网络连接问题
2. Token 权限不足
3. 推送被 GitHub 限流

**解决方案:**
```bash
# 手动推送并查看详细输出
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git push origin main --force
```

## 📝 自动化建议

### 添加到 crontab（定期同步）

```bash
# 编辑 crontab
crontab -e

# 添加以下行（每 5 分钟检查一次）
*/5 * * * * /workspace/jiedian/auto-sync-github.sh sync >> /workspace/jiedian/.git/sync.log 2>&1

# 或每小时检查一次
0 * * * * /workspace/jiedian/auto-sync-github.sh sync >> /workspace/jiedian/.git/sync.log 2>&1
```

### 创建 Git Hook（提交后自动推送）

```bash
# 创建 post-commit hook
cat > /workspace/jiedian/.git/hooks/post-commit << 'EOF'
#!/bin/bash
# 提交后自动推送
/workspace/jiedian/auto-sync-github.sh push
EOF

# 添加执行权限
chmod +x /workspace/jiedian/.git/hooks/post-commit
```

## 📂 项目文件清单

```
jiedian/
├── README.md                       # 主文档
├── QUICK_START.md                  # 快速开始指南
├── DEPLOYMENT_GUIDE.md            # 部署指南
├── DEPLOYMENT_INSTRUCTIONS.md     # 详细部署说明
├── DEPLOYMENT_COMPLETE.md         # 部署完成报告
├── SHADOWROCKET_GUIDE.md         # Shadowrocket 客户端配置指南
├── MONITOR_GUIDE.md               # 监控系统使用指南
├── GITHUB_SYNC_CONFIG.md         # 本文档
├── auto-sync-github.sh            # 自动同步脚本 ⭐
├── v2ray-deploy/                  # V2Ray 部署脚本
│   ├── deploy.sh
│   ├── simple-install.sh
│   ├── remote-install.sh
│   ├── verify-deployment.sh
│   ├── setup-certbot.sh
│   ├── config-generator.py
│   ├── v2ray-config.json.template
│   └── .env.example
└── monitor-dashboard/             # 监控面板
    ├── server.js
    ├── package.json
    ├── install-monitor.sh
    ├── public/
    ├── api/
    └── config/
```

## 🚀 快速开始

```bash
# 1. 进入项目目录
cd /workspace/jiedian

# 2. 配置 Git 凭据
git config credential.helper store

# 3. 执行首次推送
./auto-sync-github.sh force

# 4. 验证推送结果
./auto-sync-github.sh status

# 5. 访问 GitHub 仓库
# https://github.com/sofian9aadmg3hod49pc-lgtm/jiedian
```

## 📖 相关文档

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [Git Credential Storage](https://git-scm.com/docs/git-credential-store)
- [Git Hooks](https://git-scm.com/docs/githooks)

---

**最后更新:** 2026-01-31
**维护者:** sofian9aadmg3hod49pc-lgtm

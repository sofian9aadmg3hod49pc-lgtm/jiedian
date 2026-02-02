# 快速开始指南

## ✅ 部署完成！

所有文件已创建并上传到 GitHub 仓库：`sofian9aadmg3hod49pc-lgtm/jiedian`

## 📋 系统配置信息

- **服务器IP**: `216.128.151.224`
- **域名**: `ttjj11233.duckdns.org`
- **协议**: VMess + WebSocket + TLS
- **端口**: 443
- **监控端口**: 3001

## 🚀 立即部署

### 方式1: 一键部署（推荐）

```bash
cd /workspace/jiedian/v2ray-deploy
./deploy.sh
```

### 方式2: 分步部署

```bash
# 1. 连接服务器
ssh root@216.128.151.224

# 2. 运行远程安装脚本
cd /tmp/v2ray-deploy
bash remote-install.sh ttjj11233.duckdns.org 443

# 3. 查看生成的配置
cat /tmp/v2ray-info.json
```

## 📱 配置Shadowrocket

部署完成后，配置文件位于：

```bash
# vmess://链接
cat /tmp/shadowrocket-url.txt

# 完整配置
cat /tmp/shadowrocket-config.json
```

**Shadowrocket导入步骤**:
1. 复制 `vmess://` 链接
2. 打开Shadowrocket
3. 点击 `+` → 选择 `VMess`
4. 粘贴链接
5. 保存并启用

## 📊 访问监控面板

```
http://ttjj11233.duckdns.org:3001
```

**登录信息**:
- 用户名: `admin`
- 密码: `v2raymonitor`

⚠️ **首次登录后请立即修改密码！**

## 🛠️ 常用命令

```bash
# 查看V2Ray状态
systemctl status v2ray

# 重启V2Ray
systemctl restart v2ray

# 查看V2Ray日志
tail -f /var/log/v2ray/error.log

# 查看监控服务状态
systemctl status v2ray-monitor

# 重启监控服务
systemctl restart v2ray-monitor

# 健康检查
cd /workspace/jiedian/v2ray-deploy/utils
./health-check.sh
```

## 📁 文件结构

```
jiedian/
├── v2ray-deploy/              # 部署脚本
│   ├── deploy.sh             # 一键部署脚本
│   ├── remote-install.sh     # 远程安装脚本
│   ├── config-generator.py   # 配置生成器
│   └── utils/                # 工具脚本
├── monitor-dashboard/        # 监控系统
│   ├── server.js             # 监控服务器
│   ├── public/               # Web界面
│   └── api/                  # API接口
├── README.md                 # 项目说明
├── DEPLOYMENT_GUIDE.md       # 详细部署指南
├── SHADOWROCKET_GUIDE.md     # 客户端使用指南
└── MONITOR_GUIDE.md          # 监控使用指南
```

## 🔒 安全检查清单

部署完成后，请确认：

- [ ] 修改监控面板默认密码
- [ ] 配置SSH密钥登录
- [ ] 禁用密码登录（可选）
- [ ] 配置防火墙规则
- [ ] 设置SSL证书自动续期
- [ ] 配置GitHub自动备份
- [ ] 检查V2Ray日志确认无错误

## 📞 故障排查

### V2Ray无法启动
```bash
systemctl status v2ray
tail -f /var/log/v2ray/error.log
```

### SSL证书申请失败
```bash
# 检查DNS解析
nslookup ttjj11233.duckdns.org

# 检查80端口
curl -I http://ttjj11233.duckdns.org
```

### 监控面板无法访问
```bash
systemctl status v2ray-monitor
ss -tuln | grep 3001
```

## 📚 详细文档

- [部署指南](DEPLOYMENT_GUIDE.md) - 详细的部署步骤和配置
- [Shadowrocket指南](SHADOWROCKET_GUIDE.md) - 客户端配置和使用
- [监控指南](MONITOR_GUIDE.md) - 监控面板使用说明

## ⭐ 功能特性

- ✅ 一键自动化部署
- ✅ SSL证书自动申请和续期
- ✅ Shadowrocket配置自动生成
- ✅ 实时监控Web面板
- ✅ 设备连接管理
- ✅ 流量统计和图表
- ✅ GitHub自动备份
- ✅ 健康检查脚本
- ✅ 防火墙自动配置

## 🎉 下一步

1. 运行部署脚本: `./deploy.sh`
2. 导入Shadowrocket配置
3. 访问监控面板查看状态
4. 修改默认密码确保安全
5. 配置GitHub自动备份（如需要）

---

**祝使用愉快！如有问题请查看详细文档。**

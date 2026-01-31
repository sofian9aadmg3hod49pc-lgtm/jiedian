# V2Ray + Shadowrocket 节点部署

完整的V2Ray代理节点自动化部署方案，包含Shadowrocket客户端配置、SSL证书自动申请、实时监控系统。

## 功能特性

- ✅ **一键部署**: 完全自动化安装V2Ray
- ✅ **SSL证书**: 自动申请Let's Encrypt免费证书
- ✅ **客户端配置**: 自动生成Shadowrocket配置和二维码
- ✅ **实时监控**: Web监控面板，查看连接状态和流量统计
- ✅ **设备管理**: 识别和跟踪连接的设备
- ✅ **自动备份**: 配置自动备份到GitHub
- ✅ **安全防护**: 防火墙配置和安全加固

## 快速开始

### 前置要求

- Ubuntu 20.04+ 或 Debian 11+
- 域名已解析到服务器IP
- Root权限或sudo权限

### 一键部署

```bash
cd /workspace/jiedian/v2ray-deploy
chmod +x deploy.sh
./deploy.sh
```

### 配置说明

部署完成后，Shadowrocket配置文件将保存在：
- `/tmp/shadowrocket-config.json` - JSON格式配置
- `/tmp/shadowrocket-url.txt` - vmess://链接

### 监控面板访问

- **访问地址**: http://ttjj11233.duckdns.org:3001
- **默认用户名**: admin
- **默认密码**: v2raymonitor

**⚠️ 重要**: 首次登录后请修改默认密码！

## 目录结构

```
jiedian/
├── v2ray-deploy/              # V2Ray部署模块
│   ├── deploy.sh             # 主部署脚本
│   ├── remote-install.sh     # 远程安装脚本
│   ├── config-generator.py   # 配置生成器
│   ├── setup-certbot.sh      # SSL证书申请
│   └── utils/                # 工具脚本
├── monitor-dashboard/        # 监控系统
│   ├── server.js             # 监控服务器
│   ├── public/               # Web界面
│   └── api/                  # API接口
└── docs/                     # 文档
```

## 使用指南

### Shadowrocket配置

1. 复制 `vmess://` 链接
2. 在Shadowrocket中点击 `+`
3. 类型选择 `VMess`
4. 粘贴链接，点击保存
5. 启用配置并测试连接

### 监控功能

监控面板提供以下功能：
- 实时连接数统计
- 流量使用情况（上传/下载/总计）
- 系统资源监控（CPU/内存）
- 连接设备列表
- 连接历史图表

### 自动备份

配置自动备份到GitHub，需要设置环境变量：

```bash
export GITHUB_TOKEN=your_github_token
export GITHUB_REPO=sofian9aadmg3hod49pc-lgtm/jiedian
```

## 安全建议

1. 修改监控面板默认密码
2. 定期更新V2Ray到最新版本
3. 检查访问日志，发现异常及时处理
4. 使用强密码保护SSH访问
5. 定期备份配置文件

## 故障排查

### SSL证书申请失败

- 检查域名DNS解析是否正确
- 确保防火墙开放80和443端口
- 查看certbot日志：`cat /var/log/letsencrypt/letsencrypt.log`

### V2Ray无法启动

- 检查配置文件：`/usr/local/etc/v2ray/config.json`
- 查看服务状态：`systemctl status v2ray`
- 查看日志：`tail -f /var/log/v2ray/error.log`

### 监控面板无法访问

- 检查服务状态：`systemctl status v2ray-monitor`
- 检查防火墙是否开放3001端口
- 查看日志：`journalctl -u v2ray-monitor -f`

## 技术栈

- **V2Ray**: 代理服务器核心
- **Nginx**: 反向代理和SSL终端
- **Certbot**: SSL证书自动申请
- **Node.js**: 监控服务器
- **Express**: Web框架
- **Socket.io**: 实时通信

## 许可证

MIT License

## 支持

如有问题，请查看相关文档或提交Issue。

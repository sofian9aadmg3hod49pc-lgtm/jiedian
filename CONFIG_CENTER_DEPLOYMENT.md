# Shadowrocket 配置中心 - 部署指南

## 📋 功能概述

配置中心是集成在监控面板中的新功能，让用户可以直接从网页界面获取 Shadowrocket 配置，无需命令行操作。

### ✨ 主要功能

- **一键复制 vmess:// 链接**：点击按钮即可复制到剪贴板
- **二维码扫描导入**：使用手机相机扫码直接导入 Shadowrocket
- **服务器配置详情**：显示完整的连接参数（地址、端口、UUID、路径等）
- **使用说明**：iOS 和 Android 客户端的详细导入步骤

---

## 🏗️ 技术架构

```
Vultr 服务器
├── V2Ray 服务
│   └── 生成配置文件 (/tmp/v2ray-info.json)
├── 监控面板 (Node.js)
│   ├── /api/config 接口
│   │   ├── 读取配置文件
│   │   ├── 生成 vmess:// 链接
│   │   └── 创建二维码
│   └── 前端界面
│       ├── 显示配置信息
│       ├── 一键复制功能
│       └── 二维码展示
└── 用户浏览器
    └── 访问监控面板查看配置
```

---

## 📂 修改的文件清单

| 文件 | 说明 | 修改内容 |
|------|------|----------|
| `api/config.js` | 新增配置API接口 | 读取V2Ray配置、生成vmess链接、生成二维码 |
| `server.js` | 监控服务器主文件 | 注册 `/api/config` 路由 |
| `public/index.html` | 前端HTML模板 | 添加配置显示区域 |
| `public/app.js` | 前端JavaScript | 实现配置获取、复制、二维码显示功能 |
| `public/style.css` | 前端样式 | 添加配置面板样式 |
| `package.json` | 依赖配置 | 添加 `qrcode` 依赖 |

---

## 🚀 部署步骤

### 1. 准备工作

确保服务器上已安装：
- Node.js (v14+)
- npm
- V2Ray 服务
- 监控面板

### 2. 安装依赖

```bash
# 登录到 Vultr 服务器
ssh root@66.42.124.79

# 进入监控面板目录
cd /root/monitor-dashboard  # 或实际的监控面板路径

# 安装新的依赖
npm install
```

### 3. 更新配置文件权限

```bash
# 确保 V2Ray 配置文件可被监控面板读取
chmod 644 /tmp/v2ray-info.json
```

### 4. 重启监控服务

```bash
# 停止现有的监控服务
pkill -f "node.*server.js"

# 启动新的监控服务
cd /root/monitor-dashboard
nohup node server.js > /var/log/monitor.log 2>&1 &

# 检查服务状态
ps aux | grep node
```

### 5. 验证部署

访问监控面板：
```
http://ttjj11233.duckdns.org:3001
```

使用默认账号登录：
- 用户名：`admin`
- 密码：`v2raymonitor`

登录后，在页面底部应该能看到 **"Shadowrocket 配置"** 区域。

---

## 🧪 功能测试

### 测试1：访问配置API

```bash
# 测试 API 接口是否正常工作
curl -u admin:v2raymonitor http://ttjj11233.duckdns.org:3001/api/config
```

预期输出：
```json
{
  "success": true,
  "data": {
    "vmessLink": "vmess://...",
    "qrCode": "data:image/png;base64,...",
    "serverInfo": {
      "domain": "ttjj11233.duckdns.org",
      "port": 443,
      "uuid": "...",
      "ws_path": "/v2ray",
      "protocol": "VMess + WebSocket + TLS"
    },
    "instructions": {
      "ios": "...",
      "android": "..."
    }
  }
}
```

### 测试2：复制功能

1. 打开监控面板，登录
2. 找到 **Shadowrocket 配置** 区域
3. 点击 **"复制"** 按钮
4. 检查剪贴板是否有 vmess:// 链接

### 测试3：二维码功能

1. 打开监控面板，登录
2. 找到 **Shadowrocket 配置** 区域
3. 使用手机相机扫描二维码
4. 确认能识别出 vmess:// 链接

### 测试4：Shadowrocket 导入

**iOS 设备：**
1. 复制 vmess:// 链接或扫描二维码
2. 打开 Shadowrocket 应用
3. 点击右上角 `+` 按钮
4. 类型选择 `VMess`
5. 粘贴链接或扫描二维码
6. 点击右上角 `完成`
7. 点击节点开关测试连接

**Android 设备：**
1. 复制 vmess:// 链接
2. 打开 V2RayNG 应用
3. 点击 `+` 按钮
4. 选择 "从剪贴板导入"
5. 点击右上角 `完成`
6. 点击节点开关测试连接

---

## 🔍 故障排除

### 问题1：配置显示 "配置加载失败"

**原因**：
- V2Ray 配置文件不存在
- 配置文件路径错误
- 权限不足

**解决方法**：
```bash
# 检查配置文件是否存在
ls -la /tmp/v2ray-info.json

# 如果不存在，运行部署脚本生成配置
cd /root/v2ray-deploy  # 或实际路径
./deploy.sh

# 设置正确的权限
chmod 644 /tmp/v2ray-info.json
```

### 问题2：二维码无法显示

**原因**：
- qrcode 模块未安装
- Node.js 版本过低

**解决方法**：
```bash
# 进入监控面板目录
cd /root/monitor-dashboard

# 重新安装依赖
npm install qrcode

# 重启监控服务
pkill -f "node.*server.js"
nohup node server.js > /var/log/monitor.log 2>&1 &
```

### 问题3：API 返回 404 错误

**原因**：
- 新的监控代码未部署
- 路由配置错误

**解决方法**：
```bash
# 检查 server.js 是否包含 configRouter
grep "configRouter" /root/monitor-dashboard/server.js

# 如果没有，需要从本地上传更新的文件
# 使用 scp 或 rsync 上传文件到服务器
```

### 问题4：无法访问监控面板

**原因**：
- 监控服务未启动
- 端口被占用
- 防火墙阻止

**解决方法**：
```bash
# 检查服务是否运行
ps aux | grep node

# 检查端口是否监听
netstat -tlnp | grep 3001

# 检查防火墙规则
ufw status  # Ubuntu
firewall-cmd --list-all  # CentOS

# 重启服务
cd /root/monitor-dashboard
nohup node server.js > /var/log/monitor.log 2>&1 &
```

---

## 📊 性能监控

### 查看监控日志

```bash
# 查看监控服务日志
tail -f /var/log/monitor.log

# 查看 V2Ray 访问日志
tail -f /var/log/v2ray/access.log
```

### 监控面板数据

监控面板会显示：
- 当前连接数
- 上传/下载流量
- 系统资源使用率
- 连接设备列表
- 配置信息

---

## 🔒 安全建议

### 1. 修改默认密码

```bash
# 编辑监控服务配置
export MONITOR_PASSWORD="你的新密码"

# 或者直接修改 server.js 中的密码
# 默认密码: v2raymonitor
```

### 2. 限制访问IP

使用 Nginx 反向代理，限制只允许特定IP访问：

```nginx
# /etc/nginx/conf.d/monitor.conf
server {
    listen 3002;
    server_name ttjj11233.duckdns.org;
    
    # 只允许特定IP访问
    allow 你的IP;
    deny all;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. 启用 HTTPS

建议使用 Certbot 申请免费SSL证书，并通过 Nginx 代理：

```bash
# 申请SSL证书
certbot --nginx -d ttjj11233.duckdns.org
```

---

## 📱 用户使用指南

### iOS 用户

1. **访问监控面板**
   - 打开 Safari
   - 输入：`http://ttjj11233.duckdns.org:3001`
   - 登录（用户名：admin，密码：v2raymonitor）

2. **获取配置**
   - 滚动到页面底部
   - 找到 **Shadowrocket 配置** 区域
   - 点击 **"复制"** 按钮复制 vmess:// 链接
   - 或使用手机相机扫描二维码

3. **导入 Shadowrocket**
   - 打开 Shadowrocket 应用
   - 点击右上角 `+` 按钮
   - 类型选择 `VMess`
   - 粘贴链接或扫描二维码
   - 点击右上角 `完成`

4. **测试连接**
   - 点击节点右侧的开关
   - 开关变绿表示连接成功
   - 打开 Safari 访问 Google 测试

### Android 用户

1. **访问监控面板**（同iOS）

2. **获取配置**（同iOS）

3. **导入 V2RayNG**
   - 打开 V2RayNG 应用
   - 点击 `+` 按钮
   - 选择 "从剪贴板导入"
   - 点击右上角 `完成`

4. **测试连接**（同iOS）

---

## 🔄 版本更新

### 更新到最新版本

```bash
# 从 GitHub 拉取最新代码
cd /root/monitor-dashboard
git pull origin main

# 安装新的依赖
npm install

# 重启服务
pkill -f "node.*server.js"
nohup node server.js > /var/log/monitor.log 2>&1 &
```

---

## 📞 技术支持

如遇到问题，请提供以下信息：
1. 错误截图或错误日志
2. 服务器操作系统版本
3. Node.js 和 npm 版本
4. 浏览器类型和版本

---

## ✅ 部署检查清单

部署完成后，请确认以下项目：

- [ ] Node.js 和 npm 已安装
- [ ] 监控服务已启动
- [ ] `qrcode` 模块已安装
- [ ] `/tmp/v2ray-info.json` 文件存在
- [ ] 配置文件权限正确（644）
- [ ] 防火墙开放 3001 端口
- [ ] 可以访问监控面板
- [ ] 可以复制 vmess:// 链接
- [ ] 二维码可以正常显示和扫描
- [ ] Shadowrocket 可以成功导入配置
- [ ] 连接测试成功

---

## 📚 相关文档

- [V2Ray 部署指南](./DEPLOYMENT_GUIDE.md)
- [Shadowrocket 使用指南](./SHADOWROCKET_GUIDE.md)
- [监控面板使用说明](./MONITOR_GUIDE.md)

---

**部署完成后，用户就可以直接从监控面板获取配置，大大提升了使用便利性！** 🚀

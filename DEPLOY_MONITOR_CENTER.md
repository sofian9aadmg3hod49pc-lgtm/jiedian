# 监控面板部署说明

## 📦 一键部署

由于服务器 SSH 连接可能不稳定，我们准备了完整的自动部署脚本。

### 方法1：运行自动部署脚本（推荐）

```bash
cd /workspace
bash complete-deploy.sh
```

这个脚本会自动完成以下操作：
1. ✅ 打包监控面板文件
2. ✅ 上传到服务器
3. ✅ 备份现有配置
4. ✅ 解压新文件
5. ✅ 安装 Node.js 依赖
6. ✅ 设置权限并启动服务
7. ✅ 验证部署状态

### 方法2：手动部署（如果自动脚本失败）

```bash
# 1. 打包文件
cd /workspace/monitor-dashboard
tar -czf /tmp/monitor.tar.gz .

# 2. 上传到服务器
sshpass -p "8@DqCfQ9)QK)rE9[" scp -o StrictHostKeyChecking=no /tmp/monitor.tar.gz root@216.128.151.224:/tmp/

# 3. SSH登录服务器
ssh root@216.128.151.224

# 4. 备份现有配置（如果有）
cd /root
mv monitor-dashboard monitor-dashboard-backup-$(date +%Y%m%d) 2>/dev/null || true
mkdir -p monitor-dashboard

# 5. 解压新文件
cd /root/monitor-dashboard
tar -xzf /tmp/monitor.tar.gz
rm /tmp/monitor.tar.gz

# 6. 安装依赖
npm install

# 7. 设置配置文件权限
chmod 644 /tmp/v2ray-info.json 2>/dev/null || true

# 8. 停止旧服务
pkill -f "node.*server.js" 2>/dev/null || true

# 9. 启动新服务
nohup node server.js > /var/log/monitor.log 2>&1 &

# 10. 检查服务状态
ps aux | grep "[n]ode.*server.js"
tail -20 /var/log/monitor.log
```

---

## ✅ 验证部署

### 1. 访问监控面板

打开浏览器访问：
```
http://ttjj11233.duckdns.org:3001
```

### 2. 登录

- 用户名：`admin`
- 密码：`v2raymonitor`

### 3. 查看新功能

向下滚动到页面底部，应该能看到：

```
📱 Shadowrocket 配置
```

包含以下内容：
- 🔗 VMess链接 - 可一键复制
- 📱 扫码导入 - 二维码图片
- ⚙️ 服务器信息 - 完整配置详情

---

## 🧪 功能测试

### 测试复制功能

1. 点击「复制」按钮
2. 检查剪贴板是否有 vmess:// 链接
3. 链接格式：`vmess://eyJ2IjoiMiIsInBzIjoiVjJSYXkt...`

### 测试二维码功能

1. 使用手机相机扫描二维码
2. 确认能识别出 vmess:// 链接
3. Shadowrocket 应该能自动识别并导入

### 测试 Shadowrocket 导入

**iOS 用户：**
1. 复制 vmess:// 链接
2. 打开 Shadowrocket
3. 点击 `+` → 类型选择 `VMess`
4. 粘贴链接 → 保存
5. 开启节点测试连接

**Android 用户：**
1. 复制 vmess:// 链接
2. 打开 V2RayNG
3. 点击 `+` → 从剪贴板导入
4. 保存 → 测试连接

---

## 🔍 故障排除

### 问题1：无法访问监控面板

**检查服务是否运行：**
```bash
ssh root@216.128.151.224
ps aux | grep "[n]ode.*server.js"
```

**如果没有运行，查看日志：**
```bash
tail -50 /var/log/monitor.log
```

**常见错误：**
- 端口被占用：`netstat -tlnp | grep 3001`
- 权限不足：`ls -la /var/log/monitor.log`
- Node.js 未安装：`node -v`

### 问题2：配置显示「配置加载失败」

**原因：** V2Ray 配置文件不存在或权限不足

**解决：**
```bash
# 检查配置文件
ls -la /tmp/v2ray-info.json

# 如果不存在，运行部署脚本生成
cd /root/v2ray-deploy
./deploy.sh

# 设置权限
chmod 644 /tmp/v2ray-info.json
```

### 问题3：二维码无法显示

**解决：**
```bash
# 重新安装依赖
cd /root/monitor-dashboard
npm install

# 重启服务
pkill -f "node.*server.js"
nohup node server.js > /var/log/monitor.log 2>&1 &
```

### 问题4：API 返回 401 错误

**原因：** 认证失败

**解决：**
- 确认用户名和密码正确
- 检查是否使用了错误的认证方式

### 问题5：SSH 连接超时

**解决：**
- 增加连接超时时间：`-o ConnectTimeout=30`
- 检查服务器网络连接
- 尝试从不同网络连接

---

## 📊 监控日志

### 实时查看日志

```bash
ssh root@216.128.151.224
tail -f /var/log/monitor.log
```

### 查看 V2Ray 访问日志

```bash
ssh root@216.128.151.224
tail -f /var/log/v2ray/access.log
```

### 查看系统资源

```bash
ssh root@216.128.151.224
htop
# 或
top
```

---

## 🔄 回滚到旧版本

如果新版本有问题，可以快速回滚：

```bash
ssh root@216.128.151.224

# 停止新服务
pkill -f "node.*server.js"

# 恢复备份
cd /root
mv monitor-dashboard monitor-dashboard-new
mv monitor-dashboard-backup-* monitor-dashboard

# 启动旧服务
cd monitor-dashboard
nohup node server.js > /var/log/monitor.log 2>&1 &
```

---

## 🔧 高级配置

### 修改默认密码

```bash
ssh root@216.128.151.224
cd /root/monitor-dashboard

# 编辑 server.js
vim server.js

# 找到这行并修改密码
users: { 'admin': process.env.MONITOR_PASSWORD || 'v2raymonitor' },

# 保存后重启服务
pkill -f "node.*server.js"
nohup node server.js > /var/log/monitor.log 2>&1 &
```

### 修改监听端口

```bash
# 编辑 server.js
vim server.js

# 修改端口
const PORT = process.env.MONITOR_PORT || 3001;

# 重启服务
pkill -f "node.*server.js"
nohup node server.js > /var/log/monitor.log 2>&1 &
```

### 使用 Nginx 反向代理

```nginx
server {
    listen 443 ssl;
    server_name ttjj11233.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/ttjj11233.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ttjj11233.duckdns.org/privkey.pem;

    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 📱 客户端配置

### iOS (Shadowrocket)

1. 复制 vmess:// 链接
2. 打开 Shadowrocket
3. 点击右上角 `+`
4. 类型选择 `VMess`
5. 粘贴链接
6. 点击右上角 `完成`
7. 点击节点开关启用

### Android (V2RayNG)

1. 复制 vmess:// 链接
2. 打开 V2RayNG
3. 点击右上角 `+`
4. 选择 "从剪贴板导入"
5. 点击右上角 `完成`
6. 点击节点开关启用

### 测试连接

访问以下网站测试：
- https://www.google.com
- https://www.youtube.com
- https://ip.sb （应该显示服务器IP）

---

## 📞 技术支持

如遇到问题，请提供：
1. 错误截图
2. 日志内容：`tail -50 /var/log/monitor.log`
3. 系统信息：
   - 服务器操作系统版本
   - Node.js 版本：`node -v`
   - npm 版本：`npm -v`

---

**部署完成后，记得修改默认密码！** 🔒

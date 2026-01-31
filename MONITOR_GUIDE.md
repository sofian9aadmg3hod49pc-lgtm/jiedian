# 监控系统使用指南

V2Ray监控面板的详细使用说明。

## 功能概览

监控面板提供以下功能：

- 📊 **实时统计**: 连接数、流量、系统资源
- 📱 **设备管理**: 查看连接的设备列表
- 📈 **历史图表**: 连接和流量趋势图
- ⚙️ **系统控制**: 重启服务、修改配置
- 📝 **日志查看**: 实时查看访问日志

## 访问面板

### 本地访问

```bash
http://localhost:3001
```

### 远程访问

```bash
http://ttjj11233.duckdns.org:3001
```

### 登录凭证

- **用户名**: admin
- **密码**: v2raymonitor

⚠️ **安全提示**: 首次登录后请立即修改默认密码！

## 修改密码

### 方法1: 修改环境变量

编辑systemd服务文件：

```bash
nano /etc/systemd/system/v2ray-monitor.service
```

修改环境变量：

```ini
Environment="MONITOR_PASSWORD=your_new_password"
```

重启服务：

```bash
systemctl daemon-reload
systemctl restart v2ray-monitor
```

### 方法2: 修改配置文件

编辑配置文件：

```bash
nano /tmp/monitor/config/monitor-config.json
```

修改密码字段：

```json
{
  "monitor": {
    "password": "your_new_password"
  }
}
```

重启服务：

```bash
systemctl restart v2ray-monitor
```

## 界面说明

### 首页仪表盘

首页显示核心统计信息：

1. **当前连接数**: 实时在线的连接数量
2. **上传流量**: 总上传流量统计
3. **下载流量**: 总下载流量统计
4. **总流量**: 上传+下载流量合计

### 系统状态

显示服务器资源使用情况：

- CPU使用率（带进度条）
- 内存使用率（带进度条）
- 运行时间
- 服务器IP地址

### 设备列表

展示所有连接过的设备：

- 设备名称
- IP地址
- 连接状态（在线/离线）
- 连接时间
- 设备类型

### 连接历史图表

以折线图形式展示：
- 最近24小时连接趋势
- 连接峰值和低谷
- 流量使用情况

## API接口

### 统计数据API

```bash
# 获取当前统计
curl -u admin:password http://localhost:3001/api/stats

# 获取历史数据
curl -u admin:password http://localhost:3001/api/stats/history?hours=24

# 重置统计
curl -X POST -u admin:password http://localhost:3001/api/stats/reset
```

### 设备管理API

```bash
# 获取设备列表
curl -u admin:password http://localhost:3001/api/devices

# 添加设备
curl -X POST -u admin:password http://localhost:3001/api/devices \
  -H "Content-Type: application/json" \
  -d '{"name":"iPhone","ip":"192.168.1.100","type":"iOS"}'

# 更新设备状态
curl -X PUT -u admin:password http://localhost:3001/api/devices/1 \
  -H "Content-Type: application/json" \
  -d '{"online":false}'

# 删除设备
curl -X DELETE -u admin:password http://localhost:3001/api/devices/1
```

### 系统状态API

```bash
# 获取系统信息
curl -u admin:password http://localhost:3001/api/system

# 获取V2Ray状态
curl -u admin:password http://localhost:3001/api/system/v2ray

# 重启V2Ray
curl -X POST -u admin:password http://localhost:3001/api/system/v2ray/restart
```

## 数据管理

### 数据存储位置

```
/tmp/monitor/
├── data/
│   ├── stats.json          # 统计数据
│   ├── devices.json        # 设备列表
│   └── logs/               # 日志文件
└── config/
    └── monitor-config.json # 监控配置
```

### 备份数据

手动备份：

```bash
# 备份统计数据
cp /tmp/monitor/data/stats.json /backup/

# 备份设备列表
cp /tmp/monitor/data/devices.json /backup/

# 备份配置文件
cp /tmp/monitor/config/monitor-config.json /backup/
```

自动备份（通过备份脚本）：

```bash
cd /workspace/jiedian/v2ray-deploy/utils
./backup-to-github.sh
```

### 清理数据

清理历史数据：

```bash
# 清理7天前的日志
find /tmp/monitor/data/logs -mtime +7 -delete

# 清理离线设备
# （需要手动编辑devices.json文件）
```

## 告警配置

### 启用告警

编辑配置文件：

```json
{
  "alert": {
    "enabled": true,
    "cpuThreshold": 80,
    "memoryThreshold": 80,
    "connectionThreshold": 100,
    "webhook": "https://your-webhook-url"
  }
}
```

### 告警规则

- **CPU告警**: CPU使用率超过阈值
- **内存告警**: 内存使用率超过阈值
- **连接告警**: 连接数超过阈值

### Webhook通知

配置Webhook URL接收告警通知：

```json
{
  "alert": {
    "webhook": "https://api.telegram.org/botYOUR_TOKEN/sendMessage"
  }
}
```

## 性能优化

### 减少数据更新频率

修改数据收集间隔：

编辑服务器代码：

```javascript
// 从60秒改为300秒（5分钟）
setInterval(() => {
    saveStats(stats);
}, 300000);
```

### 限制历史数据量

修改配置：

```json
{
  "data": {
    "historyRetention": 24,
    "devicesRetention": 30
  }
}
```

### 优化数据库查询

对于大量设备数据，可以考虑使用数据库代替JSON文件：

- SQLite
- Redis
- MongoDB

## 安全加固

### 启用HTTPS

配置SSL证书：

```bash
# 安装certbot
apt-get install certbot

# 申请证书
certbot certonly --standalone -d ttjj11233.duckdns.org

# 配置nginx反向代理
```

Nginx配置：

```nginx
server {
    listen 443 ssl http2;
    server_name ttjj11233.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/.../fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/.../privkey.pem;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### IP白名单

限制访问来源IP：

```javascript
const ipfilter = require('express-ipfilter');

const ips = ['127.0.0.1', 'your.ip.address'];

app.use(ipfilter(ips, {
    mode: 'allow',
    log: true
}));
```

### 速率限制

防止暴力破解：

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15分钟
    max: 100 // 最多100次请求
});

app.use('/api', limiter);
```

## 故障排查

### 服务无法启动

检查服务状态：

```bash
systemctl status v2ray-monitor
```

查看日志：

```bash
journalctl -u v2ray-monitor -n 100
```

常见原因：
- 端口被占用
- 配置文件错误
- Node.js版本不兼容

### 无法访问Web界面

检查：
1. 服务是否运行
2. 防火墙是否开放3001端口
3. 网络连接是否正常

诊断命令：

```bash
# 检查端口监听
ss -tuln | grep 3001

# 测试服务
curl http://localhost:3001

# 检查防火墙
ufw status | grep 3001
```

### 数据不更新

检查：
1. 数据收集定时任务是否运行
2. V2Ray日志是否可读
3. 数据目录权限是否正确

修复方法：

```bash
# 检查权限
ls -la /tmp/monitor/data/

# 修复权限
chmod 755 /tmp/monitor/data
chmod 644 /tmp/monitor/data/*.json

# 重启服务
systemctl restart v2ray-monitor
```

## 扩展功能

### 添加更多监控指标

编辑服务器代码，添加新的监控项：

```javascript
function getExtendedStats() {
    return {
        disk: getDiskUsage(),
        network: getNetworkStats(),
        temperature: getCPUTemperature()
    };
}
```

### 集成第三方服务

- Prometheus监控
- Grafana仪表盘
- Slack通知
- Telegram机器人

### 导出报告

生成定期报告：

```bash
# 生成日报
curl -u admin:password http://localhost:3001/api/stats > daily-report.json

# 生成CSV报告
node scripts/export-report.js --format csv --period daily
```

## 升级与维护

### 升级监控系统

```bash
# 停止服务
systemctl stop v2ray-monitor

# 备份数据
cp -r /tmp/monitor /backup/

# 拉取最新代码
cd /tmp/monitor
git pull

# 安装依赖
npm install

# 启动服务
systemctl start v2ray-monitor
```

### 定期维护

建议定期执行：

1. 检查服务运行状态
2. 清理历史日志
3. 备份重要数据
4. 更新系统补丁
5. 审查访问日志

## 技术支持

### 查看实时日志

```bash
# 服务日志
journalctl -u v2ray-monitor -f

# 应用日志
tail -f /tmp/monitor/logs/app.log

# 错误日志
tail -f /tmp/monitor/logs/error.log
```

### 健康检查

使用健康检查脚本：

```bash
cd /workspace/jiedian/v2ray-deploy/utils
./health-check.sh
```

### 问题反馈

如遇到问题，请提供：
- 错误信息
- 服务日志
- 系统环境
- 复现步骤

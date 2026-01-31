# V2Ray部署指南

详细部署步骤和配置说明。

## 部署前准备

### 1. 服务器要求

- 操作系统: Ubuntu 20.04/22.04 或 Debian 11+
- 内存: 最小 512MB，推荐 1GB+
- 磁盘: 最小 10GB
- 带宽: 推荐 100Mbps+

### 2. 域名准备

使用DuckDNS获取免费域名：

1. 访问 https://www.duckdns.org
2. 注册账号并添加子域名
3. 配置DNS解析到服务器IP

例如：`ttjj11233.duckdns.org` → `66.42.124.79`

### 3. 防火墙设置

确保以下端口开放：

```bash
# SSH
ufw allow 22/tcp

# HTTP (用于证书申请)
ufw allow 80/tcp

# HTTPS (V2Ray使用)
ufw allow 443/tcp

# 监控面板
ufw allow 3001/tcp
```

## 详细部署步骤

### 步骤1: 环境检查

```bash
# 检查系统版本
cat /etc/os-release

# 检查磁盘空间
df -h

# 检查内存
free -h
```

### 步骤2: 执行部署

```bash
cd /workspace/jiedian/v2ray-deploy
chmod +x deploy.sh remote-install.sh utils/*.sh
./deploy.sh
```

部署脚本将自动完成：
- ✅ 系统更新
- ✅ 依赖安装
- ✅ V2Ray安装
- ✅ SSL证书申请
- ✅ 配置文件生成
- ✅ 服务启动
- ✅ 防火墙配置
- ✅ 监控系统部署

### 步骤3: 配置Shadowrocket

部署完成后，配置信息位于：

```bash
# 查看vmess链接
cat /tmp/shadowrocket-url.txt

# 查看完整配置
cat /tmp/shadowrocket-config.json
```

在Shadowrocket中：

1. 打开应用
2. 点击右上角 `+`
3. 选择类型 `VMess`
4. 粘贴vmess://链接
5. 点击右上角 `完成`
6. 启用配置开关
7. 点击配置进行连接测试

### 步骤4: 访问监控面板

浏览器访问：

```
http://ttjj11233.duckdns.org:3001
```

登录信息：
- 用户名: `admin`
- 密码: `v2raymonitor`

## 配置文件详解

### V2Ray配置文件

位置: `/usr/local/etc/v2ray/config.json`

```json
{
  "inbounds": [{
    "port": 443,
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "UUID",
        "alterId": 0
      }]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls"
    }
  }]
}
```

### Nginx配置

位置: `/etc/nginx/sites-available/v2ray`

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain;

    location /v2ray {
        proxy_pass http://127.0.0.1:443/v2ray;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 维护操作

### 更新V2Ray

```bash
# 停止服务
systemctl stop v2ray

# 执行更新
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 启动服务
systemctl start v2ray
```

### 续期SSL证书

证书自动续期已配置为每天检查：

```bash
# 手动续期
certbot renew --force-renewal

# 查看证书信息
certbot certificates
```

### 重启服务

```bash
# 重启V2Ray
systemctl restart v2ray

# 重启Nginx
systemctl restart nginx

# 重启监控服务
systemctl restart v2ray-monitor
```

### 查看日志

```bash
# V2Ray访问日志
tail -f /var/log/v2ray/access.log

# V2Ray错误日志
tail -f /var/log/v2ray/error.log

# Nginx日志
tail -f /var/log/nginx/error.log

# 监控服务日志
journalctl -u v2ray-monitor -f
```

## 性能优化

### TCP参数优化

编辑 `/etc/sysctl.conf`：

```bash
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_congestion_control = bbr
```

应用配置：

```bash
sysctl -p
```

### V2Ray优化

编辑 `/usr/local/etc/v2ray/config.json`，添加：

```json
{
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5
      }
    }
  }
}
```

## 安全加固

### SSH安全

编辑 `/etc/ssh/sshd_config`：

```bash
# 禁用密码登录（推荐使用密钥）
PasswordAuthentication no

# 禁用root登录
PermitRootLogin no

# 修改默认端口
Port 2222
```

重启SSH：

```bash
systemctl restart sshd
```

### Fail2Ban安装

```bash
apt-get install -y fail2ban

# 配置保护SSH
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban
```

## 常见问题

### Q1: SSL证书申请失败

**原因**: 域名未解析或80端口未开放

**解决**:
```bash
# 检查DNS解析
nslookup your-domain

# 检查80端口
curl -I http://your-domain
```

### Q2: Shadowrocket连接失败

**原因**: 防火墙阻止或配置错误

**解决**:
```bash
# 检查端口监听
ss -tuln | grep 443

# 检查V2Ray状态
systemctl status v2ray

# 查看日志
tail -f /var/log/v2ray/error.log
```

### Q3: 监控面板无法访问

**原因**: 服务未启动或防火墙阻止

**解决**:
```bash
# 检查服务状态
systemctl status v2ray-monitor

# 检查防火墙
ufw status | grep 3001

# 重启服务
systemctl restart v2ray-monitor
```

## 备份与恢复

### 手动备份

```bash
# 备份V2Ray配置
cp /usr/local/etc/v2ray/config.json /backup/

# 备份SSL证书
cp -r /etc/letsencrypt /backup/

# 备份监控数据
tar -czf /backup/monitor-data.tar.gz /tmp/monitor/data
```

### 自动备份

已在部署脚本中配置，每日自动备份到GitHub。

查看备份任务：

```bash
crontab -l | grep backup
```

## 卸载

### 完全卸载V2Ray

```bash
# 停止服务
systemctl stop v2ray

# 卸载
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --remove

# 删除配置
rm -rf /usr/local/etc/v2ray
rm -rf /var/log/v2ray
```

### 卸载监控系统

```bash
systemctl stop v2ray-monitor
systemctl disable v2ray-monitor
rm /etc/systemd/system/v2ray-monitor.service
rm -rf /tmp/monitor
```

## 获取帮助

- 查看日志文件定位问题
- 检查服务状态确认运行情况
- 使用健康检查脚本验证配置

```bash
cd /workspace/jiedian/v2ray-deploy/utils
./health-check.sh
```

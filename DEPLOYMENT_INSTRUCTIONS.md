# 🚀 V2Ray部署说明

由于当前环境无法直接SSH连接到服务器，请按照以下步骤手动部署：

## 方法1: 通过SSH手动部署（推荐）

### 步骤1: 连接到服务器

```bash
ssh root@66.42.124.79
# 输入密码: 8@DqCfQ9)QK)rE9[
```

### 步骤2: 下载并运行安装脚本

```bash
# 从GitHub下载
cd /tmp
wget https://raw.githubusercontent.com/sofian9aadmg3hod49pc-lgtm/jiedian/main/v2ray-deploy/simple-install.sh
chmod +x simple-install.sh
bash simple-install.sh
```

或者手动执行以下命令：

```bash
# 1. 更新系统
apt-get update && apt-get upgrade -y

# 2. 安装依赖
apt-get install -y curl wget unzip nginx python3 python3-pip certbot

# 3. 安装V2Ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 4. 生成UUID并创建配置
UUID=$(cat /proc/sys/kernel/random/uuid)
DOMAIN="ttjj11233.duckdns.org"
PORT=443

cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": ${PORT},
    "listen": "127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "${UUID}",
        "alterId": 0
      }]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "tlsSettings": {
        "serverName": "${DOMAIN}",
        "certificates": [{
          "certificateFile": "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem",
          "keyFile": "/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
        }]
      },
      "wsSettings": {
        "path": "/v2ray"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF

echo "UUID: ${UUID}"
echo "${UUID}" > /tmp/v2ray-uuid.txt
```

### 步骤3: 申请SSL证书

```bash
# 确保域名已解析到服务器IP
nslookup ttjj11233.duckdns.org

# 申请证书
certbot certonly --nginx -d ttjj11233.duckdns.org --non-interactive \
    --agree-tos --email admin@ttjj11233.duckdns.org --no-eff-email --redirect
```

### 步骤4: 配置Nginx

```bash
cat > /etc/nginx/sites-available/v2ray <<'EOF'
server {
    listen 443 ssl http2;
    server_name ttjj11233.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/ttjj11233.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ttjj11233.duckdns.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location /v2ray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:443/v2ray;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;
    server_name ttjj11233.duckdns.org;
    return 301 https://$server_name$request_uri;
}
EOF

ln -sf /etc/nginx/sites-available/v2ray /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
```

### 步骤5: 配置防火墙

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

### 步骤6: 启动V2Ray

```bash
systemctl enable v2ray
systemctl restart v2ray

# 设置证书自动续期
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet --deploy-hook 'systemctl restart v2ray'") | crontab -
```

### 步骤7: 生成Shadowrocket配置

```bash
# 获取UUID
UUID=$(cat /tmp/v2ray-uuid.txt)

# 生成vmess配置
VMESS_CONFIG='{
  "v": "2",
  "ps": "V2Ray-ttjj11233.duckdns.org",
  "add": "ttjj11233.duckdns.org",
  "port": "443",
  "id": "'${UUID}'",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "ttjj11233.duckdns.org",
  "path": "/v2ray",
  "tls": "tls"
}'

# 生成vmess链接
VMESS_B64=$(echo -n "${VMESS_CONFIG}" | base64 -w 0)

echo "VMess链接:"
echo "vmess://${VMESS_B64}"
```

## 方法2: 使用自动化脚本（需要网络连接）

如果GitHub可以访问，可以使用以下一键命令：

```bash
curl -fsSL https://raw.githubusercontent.com/sofian9aadmg3hod49pc-lgtm/jiedian/main/v2ray-deploy/simple-install.sh | bash
```

## 验证部署

部署完成后，运行以下命令验证：

```bash
# 检查V2Ray状态
systemctl status v2ray

# 检查Nginx状态
systemctl status nginx

# 检查端口监听
ss -tuln | grep 443

# 查看V2Ray日志
tail -f /var/log/v2ray/error.log
```

## 配置Shadowrocket

1. 复制步骤7生成的 `vmess://` 链接
2. 打开Shadowrocket
3. 点击 `+` → 选择 `VMess`
4. 粘贴链接
5. 点击完成
6. 启用配置开关

## 安装监控系统（可选）

```bash
# 安装Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 下载并安装监控
cd /tmp
wget https://github.com/sofian9aadmg3hod49pc-lgtm/jiedian/archive/refs/heads/main.zip
unzip main.zip
cd jiedian-main/monitor-dashboard

# 安装依赖
npm install

# 创建systemd服务
cat > /etc/systemd/system/v2ray-monitor.service <<'EOF'
[Unit]
Description=V2Ray Monitor Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/tmp/monitor
Environment="NODE_ENV=production"
Environment="MONITOR_PORT=3001"
Environment="MONITOR_PASSWORD=v2raymonitor"
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 创建数据目录
mkdir -p /tmp/monitor/data
cp -r * /tmp/monitor/

# 启动服务
systemctl daemon-reload
systemctl enable v2ray-monitor
systemctl start v2ray-monitor

# 开放防火墙
ufw allow 3001/tcp
```

## 访问监控面板

```
URL: http://ttjj11233.duckdns.org:3001
用户名: admin
密码: v2raymonitor
```

## 故障排查

### SSL证书申请失败

确保域名解析正确：
```bash
nslookup ttjj11233.duckdns.org
```

应该返回 `66.42.124.79`

### V2Ray无法启动

查看错误日志：
```bash
systemctl status v2ray
tail -f /var/log/v2ray/error.log
```

### 443端口被占用

检查端口占用：
```bash
ss -tuln | grep 443
lsof -i :443
```

## 下一步

部署完成后：
1. 导入Shadowrocket配置
2. 测试连接是否正常
3. 安装监控系统（可选）
4. 修改默认密码确保安全
5. 配置自动备份到GitHub

#!/bin/bash
# =====================================================
# 简化部署脚本 - 直接在服务器上运行
# =====================================================

DOMAIN="ttjj11233.duckdns.org"
PORT=443

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. 更新系统
log_info "步骤 1/8: 更新系统..."
apt-get update && apt-get upgrade -y

# 2. 安装依赖
log_info "步骤 2/8: 安装依赖..."
apt-get install -y curl wget unzip nginx python3 python3-pip certbot

# 3. 安装V2Ray
log_info "步骤 3/8: 安装V2Ray..."
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 4. 生成配置
log_info "步骤 4/8: 生成V2Ray配置..."
UUID=$(cat /proc/sys/kernel/random/uuid)
WS_PATH="/v2ray"

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
        "path": "${WS_PATH}"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF

# 保存配置信息
cat > /tmp/v2ray-info.json <<EOF
{
  "uuid": "${UUID}",
  "domain": "${DOMAIN}",
  "port": ${PORT},
  "ws_path": "${WS_PATH}",
  "protocol": "vmess"
}
EOF

log_info "UUID: ${UUID}"

# 5. 申请SSL证书
log_info "步骤 5/8: 申请SSL证书..."
certbot certonly --nginx -d ${DOMAIN} --non-interactive \
    --agree-tos --email admin@${DOMAIN} --no-eff-email --redirect

# 6. 配置Nginx
log_info "步骤 6/8: 配置Nginx..."
cat > /etc/nginx/sites-available/v2ray <<EOF
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location /v2ray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${PORT}/v2ray;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
EOF

ln -sf /etc/nginx/sites-available/v2ray /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# 7. 配置防火墙
log_info "步骤 7/8: 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
fi

# 8. 启动V2Ray
log_info "步骤 8/8: 启动V2Ray服务..."
systemctl enable v2ray
systemctl restart v2ray

# 设置证书自动续期
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet --deploy-hook 'systemctl restart v2ray'") | crontab -

# 生成vmess链接
log_info "========================================="
log_info "部署完成！"
log_info "========================================="
echo ""
echo "服务器信息:"
echo "  域名: ${DOMAIN}"
echo "  端口: ${PORT}"
echo "  UUID: ${UUID}"
echo "  WebSocket路径: ${WS_PATH}"
echo ""

# 生成vmess配置
VMESS_CONFIG=$(cat <<EOF
{
  "v": "2",
  "ps": "V2Ray-${DOMAIN}",
  "add": "${DOMAIN}",
  "port": "${PORT}",
  "id": "${UUID}",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "${DOMAIN}",
  "path": "${WS_PATH}",
  "tls": "tls"
}
EOF
)

VMESS_B64=$(echo -n "${VMESS_CONFIG}" | base64 -w 0)
echo "VMess链接:"
echo "  vmess://${VMESS_B64}"
echo ""
echo "配置已保存到: /tmp/v2ray-info.json"
echo "========================================="

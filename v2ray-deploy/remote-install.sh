#!/bin/bash
# =====================================================
# V2Ray 远程安装脚本
# 在目标服务器上安装和配置V2Ray
# =====================================================

set -e

DOMAIN=$1
PORT=${2:-443}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root用户运行此脚本"
        exit 1
    fi
}

# 更新系统
update_system() {
    log_info "更新系统..."
    
    if [ -f /etc/debian_version ]; then
        apt-get update && apt-get upgrade -y
    elif [ -f /etc/redhat-release ]; then
        yum update -y
    else
        log_warning "未知的系统类型"
    fi
    
    log_success "系统更新完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装依赖包..."
    
    if [ -f /etc/debian_version ]; then
        apt-get install -y curl wget uuid-runtime unzip nginx python3 python3-pip
    elif [ -f /etc/redhat-release ]; then
        yum install -y curl wget unzip nginx python3 python3-pip
    fi
    
    log_success "依赖安装完成"
}

# 安装V2Ray
install_v2ray() {
    log_info "安装V2Ray..."
    
    # 使用官方安装脚本
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
    
    # 检查安装
    if ! command -v v2ray &> /dev/null; then
        log_error "V2Ray安装失败"
        exit 1
    fi
    
    log_success "V2Ray安装完成"
}

# 生成随机UUID
generate_uuid() {
    cat /proc/sys/kernel/random/uuid
}

# 创建V2Ray配置
create_v2ray_config() {
    log_info "创建V2Ray配置..."
    
    local uuid=$(generate_uuid)
    local ws_path="/v2ray"
    
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
        "id": "${uuid}",
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
        "path": "${ws_path}"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [{
      "type": "field",
      "ip": ["geoip:private"],
      "outboundTag": "block"
    }]
  }
}
EOF

    # 保存配置信息到临时文件
    cat > /tmp/v2ray-info.json <<EOF
{
  "uuid": "${uuid}",
  "domain": "${DOMAIN}",
  "port": ${PORT},
  "ws_path": "${ws_path}",
  "protocol": "vmess"
}
EOF
    
    log_success "V2Ray配置创建完成"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    # 检查ufw
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
        log_success "UFW防火墙配置完成"
    fi
    
    # 检查firewalld
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
        log_success "Firewalld配置完成"
    fi
}

# 配置Nginx反向代理
setup_nginx() {
    log_info "配置Nginx反向代理..."
    
    # 创建V2Ray网站配置
    cat > /etc/nginx/sites-available/v2ray <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
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
EOF

    # 启用网站
    ln -sf /etc/nginx/sites-available/v2ray /etc/nginx/sites-enabled/
    
    # 测试并重启Nginx
    nginx -t && systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 启动V2Ray服务
start_v2ray() {
    log_info "启动V2Ray服务..."
    
    systemctl enable v2ray
    systemctl restart v2ray
    
    # 检查服务状态
    if systemctl is-active --quiet v2ray; then
        log_success "V2Ray服务启动成功"
    else
        log_error "V2Ray服务启动失败"
        systemctl status v2ray
        exit 1
    fi
}

# 申请SSL证书
install_certbot() {
    log_info "安装Certbot..."
    
    if [ -f /etc/debian_version ]; then
        apt-get install -y certbot python3-certbot-nginx
    elif [ -f /etc/redhat-release ]; then
        yum install -y certbot python3-certbot-nginx
    fi
    
    log_success "Certbot安装完成"
}

# 申请SSL证书
obtain_ssl_certificate() {
    log_info "申请SSL证书: ${DOMAIN}"
    
    # 先申请证书
    certbot certonly --nginx -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN} --no-eff-email
    
    if [ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
        log_success "SSL证书申请成功"
    else
        log_warning "SSL证书申请失败，使用自签名证书"
        generate_self_signed_cert
    fi
    
    # 设置自动续期
    (crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet --deploy-hook 'systemctl restart v2ray'") | crontab -
}

# 生成自签名证书（备用方案）
generate_self_signed_cert() {
    log_warning "生成自签名证书..."
    
    mkdir -p /etc/letsencrypt/live/${DOMAIN}
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/letsencrypt/live/${DOMAIN}/privkey.pem \
        -out /etc/letsencrypt/live/${DOMAIN}/fullchain.pem \
        -subj "/CN=${DOMAIN}"
    
    log_warning "自签名证书已生成，Shadowrocket需要跳过证书验证"
}

# 主函数
main() {
    log_info "========================================="
    log_info "V2Ray 远程安装脚本"
    log_info "========================================="
    echo ""
    
    check_root
    update_system
    install_dependencies
    install_certbot
    obtain_ssl_certificate
    setup_firewall
    install_v2ray
    create_v2ray_config
    setup_nginx
    start_v2ray
    
    echo ""
    log_success "========================================="
    log_success "V2Ray安装配置完成！"
    log_success "========================================="
}

# 运行主函数
main "$@"

#!/bin/bash
# =====================================================
# SSL证书自动申请脚本
# =====================================================

DOMAIN=$1

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 安装Certbot
install_certbot() {
    echo -e "${GREEN}[INFO]${NC} 安装Certbot..."
    
    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    elif [ -f /etc/redhat-release ]; then
        yum install -y certbot python3-certbot-nginx
    fi
}

# 申请证书
obtain_certificate() {
    echo -e "${GREEN}[INFO]${NC} 申请SSL证书: ${DOMAIN}"
    
    certbot certonly --nginx -d ${DOMAIN} --non-interactive \
        --agree-tos --email admin@${DOMAIN} --no-eff-email
    
    if [ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]; then
        echo -e "${GREEN}[SUCCESS]${NC} 证书申请成功"
        return 0
    else
        echo -e "${YELLOW}[WARNING]${NC} 证书申请失败"
        return 1
    fi
}

# 设置自动续期
setup_auto_renewal() {
    echo -e "${GREEN}[INFO]${NC} 设置证书自动续期..."
    
    # 添加cron任务
    (crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --quiet --deploy-hook 'systemctl restart v2ray && systemctl restart nginx'") | crontab -
    
    echo -e "${GREEN}[SUCCESS]${NC} 自动续期已配置"
}

# 主函数
main() {
    install_certbot
    if obtain_certificate; then
        setup_auto_renewal
        exit 0
    else
        exit 1
    fi
}

main

#!/bin/bash
# =====================================================
# 防火墙配置脚本
# =====================================================

# 允许的端口
SSH_PORT=22
HTTP_PORT=80
HTTPS_PORT=443
V2RAY_PORT=443

# 颜色输出
GREEN='\033[0;32m'
NC='\033[0m'

# 配置UFW
setup_ufw() {
    if command -v ufw &> /dev/null; then
        echo "配置UFW防火墙..."
        
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        
        ufw allow ${SSH_PORT}/tcp comment 'SSH'
        ufw allow ${HTTP_PORT}/tcp comment 'HTTP'
        ufw allow ${HTTPS_PORT}/tcp comment 'HTTPS'
        
        ufw --force enable
        
        echo -e "${GREEN}[SUCCESS]${NC} UFW防火墙配置完成"
        ufw status numbered
    fi
}

# 配置Firewalld
setup_firewalld() {
    if command -v firewall-cmd &> /dev/null; then
        echo "配置Firewalld防火墙..."
        
        firewall-cmd --permanent --zone=public --add-service=ssh
        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --add-service=https
        
        firewall-cmd --reload
        
        echo -e "${GREEN}[SUCCESS]${NC} Firewalld防火墙配置完成"
        firewall-cmd --list-all
    fi
}

# 配置iptables（备用）
setup_iptables() {
    if command -v iptables &> /dev/null; then
        echo "配置iptables防火墙..."
        
        # 清空现有规则
        iptables -F
        iptables -X
        
        # 默认策略
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        
        # 允许本地连接
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        
        # 允许特定端口
        iptables -A INPUT -p tcp --dport ${SSH_PORT} -j ACCEPT
        iptables -A INPUT -p tcp --dport ${HTTP_PORT} -j ACCEPT
        iptables -A INPUT -p tcp --dport ${HTTPS_PORT} -j ACCEPT
        
        # 保存规则
        if [ -f /etc/debian_version ]; then
            apt-get install -y iptables-persistent
        elif [ -f /etc/redhat-release ]; then
            yum install -y iptables-services
        fi
        
        echo -e "${GREEN}[SUCCESS]${NC} iptables防火墙配置完成"
        iptables -L -n
    fi
}

# 主函数
main() {
    setup_ufw || setup_firewalld || setup_iptables
}

main

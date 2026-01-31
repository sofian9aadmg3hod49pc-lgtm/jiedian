#!/bin/bash
# =====================================================
# 监控系统安装脚本
# =====================================================

set -e

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Node.js
check_nodejs() {
    if ! command -v node &> /dev/null; then
        log_info "安装Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    log_info "Node.js版本: $(node --version)"
}

# 安装依赖
install_dependencies() {
    log_info "安装Node.js依赖..."
    npm install
}

# 创建数据目录
create_data_dir() {
    mkdir -p /tmp/monitor/data
    chmod 755 /tmp/monitor/data
}

# 创建systemd服务
create_systemd_service() {
    log_info "创建systemd服务..."
    
    cat > /etc/systemd/system/v2ray-monitor.service <<EOF
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

    systemctl daemon-reload
    systemctl enable v2ray-monitor
}

# 启动服务
start_service() {
    log_info "启动监控服务..."
    systemctl start v2ray-monitor
    
    sleep 3
    
    if systemctl is-active --quiet v2ray-monitor; then
        log_info "监控服务启动成功"
        systemctl status v2ray-monitor --no-pager
    else
        log_error "监控服务启动失败"
        exit 1
    fi
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 3001/tcp
    fi
    
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=3001/tcp
        firewall-cmd --reload
    fi
}

# 保存凭证
save_credentials() {
    log_info "保存访问凭证..."
    
    cat > /tmp/monitor/credentials.txt <<EOF
========================================
V2Ray 监控系统访问凭证
========================================

访问地址: http://$(hostname -I | awk '{print $1}'):3001
用户名: admin
密码: v2raymonitor

请修改默认密码以确保安全！

修改方法:
1. 编辑服务文件: /etc/systemd/system/v2ray-monitor.service
2. 修改 MONITOR_PASSWORD 环境变量
3. 重启服务: systemctl restart v2ray-monitor
========================================
EOF
    
    chmod 600 /tmp/monitor/credentials.txt
}

# 主函数
main() {
    log_info "========================================="
    log_info "V2Ray 监控系统安装"
    log_info "========================================="
    
    check_nodejs
    install_dependencies
    create_data_dir
    create_systemd_service
    setup_firewall
    start_service
    save_credentials
    
    echo ""
    log_info "========================================="
    log_info "监控系统安装完成！"
    log_info "========================================="
    cat /tmp/monitor/credentials.txt
}

main

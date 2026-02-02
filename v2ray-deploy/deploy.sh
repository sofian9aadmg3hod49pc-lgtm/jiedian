#!/bin/bash
# =====================================================
# V2Ray + Shadowrocket 一键部署脚本
# 自动安装V2Ray、申请SSL证书、配置Shadowrocket客户端
# =====================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置参数
VULTR_IP="216.128.151.224"
VULTR_PASSWORD="8@DqCfQ9)QK)rE9["
DOMAIN="ttjj11233.duckdns.org"
PORT=443
PROTOCOL="vmess"
TRANSPORT="ws+tls"

# 日志函数
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

# 检查本地环境
check_local_env() {
    log_info "检查本地环境..."
    
    if ! command -v sshpass &> /dev/null; then
        log_warning "sshpass未安装，将提示输入密码"
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装"
        exit 1
    fi
    
    log_success "本地环境检查完成"
}

# 验证服务器连接
verify_server_connection() {
    log_info "验证服务器连接: ${VULTR_IP}"
    
    if sshpass -p "${VULTR_PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@${VULTR_IP} "echo 'Connection successful'" 2>/dev/null; then
        log_success "服务器连接成功"
        return 0
    else
        log_error "无法连接到服务器 ${VULTR_IP}"
        exit 1
    fi
}

# 验证域名解析
verify_domain_resolution() {
    log_info "验证域名解析: ${DOMAIN}"
    
    resolved_ip=$(nslookup ${DOMAIN} 2>/dev/null | grep "Address" | tail -1 | awk '{print $2}')
    
    if [ "$resolved_ip" = "$VULTR_IP" ]; then
        log_success "域名解析正确: ${DOMAIN} -> ${VULTR_IP}"
        return 0
    else
        log_warning "域名解析不匹配: ${DOMAIN} -> ${resolved_ip} (期望: ${VULTR_IP})"
        read -p "是否继续? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 上传文件到服务器
upload_files() {
    log_info "上传部署文件到服务器..."
    
    local script_dir=$(dirname "$0")
    
    sshpass -p "${VULTR_PASSWORD}" ssh -o StrictHostKeyChecking=no root@${VULTR_IP} "mkdir -p /tmp/v2ray-deploy"
    
    sshpass -p "${VULTR_PASSWORD}" scp -o StrictHostKeyChecking=no \
        ${script_dir}/remote-install.sh \
        ${script_dir}/v2ray-config.json.template \
        ${script_dir}/setup-certbot.sh \
        root@${VULTR_IP}:/tmp/v2ray-deploy/
    
    log_success "文件上传完成"
}

# 执行远程安装
execute_remote_install() {
    log_info "执行远程安装..."
    
    sshpass -p "${VULTR_PASSWORD}" ssh -o StrictHostKeyChecking=no root@${VULTR_IP} \
        "bash /tmp/v2ray-deploy/remote-install.sh ${DOMAIN} ${PORT}"
    
    log_success "远程安装完成"
}

# 生成Shadowrocket配置
generate_shadowrocket_config() {
    log_info "生成Shadowrocket配置..."
    
    local script_dir=$(dirname "$0")
    
    if [ ! -f "${script_dir}/config-generator.py" ]; then
        log_error "配置生成器不存在"
        exit 1
    fi
    
    # 从服务器获取生成的UUID和配置
    sshpass -p "${VULTR_PASSWORD}" ssh -o StrictHostKeyChecking=no root@${VULTR_IP} "cat /tmp/v2ray-info.json" > /tmp/v2ray-info.json
    
    python3 ${script_dir}/config-generator.py /tmp/v2ray-info.json ${DOMAIN} ${PORT}
    
    log_success "Shadowrocket配置已生成"
}

# 部署监控系统
deploy_monitoring() {
    log_info "部署监控系统..."
    
    local script_dir=$(dirname "$0")
    
    sshpass -p "${VULTR_PASSWORD}" ssh -o StrictHostKeyChecking=no root@${VULTR_IP} "mkdir -p /tmp/monitor"
    
    sshpass -p "${VULTR_PASSWORD}" scp -o StrictHostKeyChecking=no -r \
        ${script_dir}/../monitor-dashboard/ \
        root@${VULTR_IP}:/tmp/monitor/
    
    sshpass -p "${VULTR_PASSWORD}" ssh -o StrictHostKeyChecking=no root@${VULTR_IP} \
        "cd /tmp/monitor && bash install-monitor.sh"
    
    log_success "监控系统部署完成"
}

# 显示部署结果
show_deployment_result() {
    log_info "========================================="
    log_success "部署完成！"
    log_info "========================================="
    echo ""
    log_info "服务器信息:"
    echo "  IP地址: ${VULTR_IP}"
    echo "  域名: ${DOMAIN}"
    echo "  端口: ${PORT}"
    echo "  协议: ${PROTOCOL}"
    echo ""
    log_info "Shadowrocket配置:"
    echo "  配置链接已保存到: /tmp/shadowrocket-config.json"
    echo "  vmess://链接已保存到: /tmp/shadowrocket-url.txt"
    echo ""
    log_info "监控面板:"
    echo "  访问地址: http://${DOMAIN}:3001"
    echo "  管理密码: 查看服务器上的 /tmp/monitor/credentials.txt"
    echo ""
    log_info "下一步操作:"
    echo "  1. 在Shadowrocket中导入配置"
    echo "  2. 测试连接是否正常"
    echo "  3. 访问监控面板查看使用情况"
    echo ""
}

# 主函数
main() {
    echo ""
    log_info "========================================="
    log_info "V2Ray + Shadowrocket 一键部署"
    log_info "========================================="
    echo ""
    
    check_local_env
    verify_domain_resolution
    verify_server_connection
    upload_files
    execute_remote_install
    generate_shadowrocket_config
    deploy_monitoring
    show_deployment_result
    
    log_success "所有步骤完成！"
}

# 运行主函数
main "$@"

#!/bin/bash
# =====================================================
# V2Ray 健康检查脚本
# =====================================================

PORT=443
DOMAIN="ttjj11233.duckdns.org"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查V2Ray服务状态
check_v2ray_service() {
    if systemctl is-active --quiet v2ray; then
        echo -e "${GREEN}[OK]${NC} V2Ray服务运行正常"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} V2Ray服务未运行"
        return 1
    fi
}

# 检查端口监听
check_port_listening() {
    if ss -tuln | grep -q ":${PORT}"; then
        echo -e "${GREEN}[OK]${NC} 端口 ${PORT} 正在监听"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} 端口 ${PORT} 未监听"
        return 1
    fi
}

# 检查SSL证书
check_ssl_certificate() {
    if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
        expiry=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" | cut -d= -f2)
        echo -e "${GREEN}[OK]${NC} SSL证书有效 (到期: ${expiry})"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} SSL证书不存在"
        return 1
    fi
}

# 检查Nginx状态
check_nginx_service() {
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}[OK]${NC} Nginx服务运行正常"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} Nginx服务未运行"
        return 1
    fi
}

# 测试代理连接
test_proxy_connection() {
    echo -e "${YELLOW}[TEST]${NC} 测试代理连接..."
    
    # 使用curl测试（需要代理配置）
    # 这里只是示例，实际测试需要配置代理
    # if curl --socks5 127.0.0.1:1080 -s https://www.google.com > /dev/null; then
    #     echo -e "${GREEN}[OK]${NC} 代理连接正常"
    #     return 0
    # else
    #     echo -e "${RED}[FAIL]${NC} 代理连接失败"
    #     return 1
    # fi
    echo -e "${YELLOW}[INFO]${NC} 代理连接测试需要客户端配置"
    return 0
}

# 检查日志错误
check_logs() {
    error_count=$(grep -c "error\|Error\|ERROR" /var/log/v2ray/error.log 2>/dev/null || echo 0)
    
    if [ $error_count -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} 无错误日志"
        return 0
    else
        echo -e "${YELLOW}[WARNING]${NC} 发现 ${error_count} 个错误日志"
        tail -5 /var/log/v2ray/error.log
        return 1
    fi
}

# 生成健康报告
generate_report() {
    echo ""
    echo "========================================"
    echo "V2Ray 健康检查报告"
    echo "========================================"
    echo ""
    
    check_v2ray_service
    check_nginx_service
    check_port_listening
    check_ssl_certificate
    test_proxy_connection
    check_logs
    
    echo ""
    echo "========================================"
    echo "检查完成"
    echo "========================================"
}

# 主函数
main() {
    generate_report
}

main

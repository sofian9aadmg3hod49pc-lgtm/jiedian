#!/bin/bash
# =====================================================
# 部署验证脚本
# 检查V2Ray部署是否成功
# =====================================================

VULTR_IP="66.42.124.79"
DOMAIN="ttjj11233.duckdns.org"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "V2Ray 部署验证"
echo "========================================"
echo ""

# 检查列表
checks=()

# 1. 检查域名解析
echo "[1/8] 检查域名解析..."
resolved_ip=$(nslookup ${DOMAIN} 2>/dev/null | grep "Address" | tail -1 | awk '{print $2}')
if [ "$resolved_ip" = "$VULTR_IP" ]; then
    echo -e "${GREEN}[OK]${NC} 域名解析正确: ${DOMAIN} -> ${VULTR_IP}"
    checks+=("域名解析")
else
    echo -e "${RED}[FAIL]${NC} 域名解析错误: ${DOMAIN} -> ${resolved_ip} (期望: ${VULTR_IP})"
fi

# 2. 检查SSH连接
echo ""
echo "[2/8] 检查SSH连接..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@${VULTR_IP} "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${GREEN}[OK]${NC} SSH连接成功"
    checks+=("SSH连接")
else
    echo -e "${RED}[FAIL]${NC} SSH连接失败"
fi

# 3. 检查V2Ray服务
echo ""
echo "[3/8] 检查V2Ray服务..."
if ssh root@${VULTR_IP} "systemctl is-active --quiet v2ray"; then
    echo -e "${GREEN}[OK]${NC} V2Ray服务运行中"
    checks+=("V2Ray服务")
else
    echo -e "${RED}[FAIL]${NC} V2Ray服务未运行"
fi

# 4. 检查Nginx服务
echo ""
echo "[4/8] 检查Nginx服务..."
if ssh root@${VULTR_IP} "systemctl is-active --quiet nginx"; then
    echo -e "${GREEN}[OK]${NC} Nginx服务运行中"
    checks+=("Nginx服务")
else
    echo -e "${RED}[FAIL]${NC} Nginx服务未运行"
fi

# 5. 检查443端口
echo ""
echo "[5/8] 检查443端口监听..."
if ssh root@${VULTR_IP} "ss -tuln | grep -q ':443'"; then
    echo -e "${GREEN}[OK]${NC} 443端口正在监听"
    checks+=("443端口")
else
    echo -e "${RED}[FAIL]${NC} 443端口未监听"
fi

# 6. 检查SSL证书
echo ""
echo "[6/8] 检查SSL证书..."
if ssh root@${VULTR_IP} "[ -f /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ]"; then
    echo -e "${GREEN}[OK]${NC} SSL证书存在"
    expiry=$(ssh root@${VULTR_IP} "openssl x509 -enddate -noout -in /etc/letsencrypt/live/${DOMAIN}/fullchain.pem | cut -d= -f2")
    echo "      证书到期: ${expiry}"
    checks+=("SSL证书")
else
    echo -e "${RED}[FAIL]${NC} SSL证书不存在"
fi

# 7. 检查HTTPS连接
echo ""
echo "[7/8] 检查HTTPS连接..."
if curl -sk -I https://${DOMAIN} | grep -q "HTTP/2"; then
    echo -e "${GREEN}[OK]${NC} HTTPS连接正常"
    checks+=("HTTPS连接")
else
    echo -e "${YELLOW}[WARN]${NC} HTTPS连接可能有问题"
fi

# 8. 检查监控服务
echo ""
echo "[8/8] 检查监控服务..."
if ssh root@${VULTR_IP} "systemctl is-active --quiet v2ray-monitor"; then
    echo -e "${GREEN}[OK]${NC} 监控服务运行中"
    checks+=("监控服务")
else
    echo -e "${YELLOW}[WARN]${NC} 监控服务未运行（可选）"
fi

# 总结
echo ""
echo "========================================"
echo "验证总结"
echo "========================================"
echo "通过检查: ${#checks[@]}/8"
echo ""
echo "已通过的检查:"
for check in "${checks[@]}"; do
    echo "  ✓ ${check}"
done

if [ ${#checks[@]} -ge 6 ]; then
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} 核心功能部署成功！"
    echo ""
    echo "下一步:"
    echo "1. 导入Shadowrocket配置: cat /tmp/shadowrocket-url.txt"
    echo "2. 访问监控面板: http://${DOMAIN}:3001"
    echo "3. 修改默认密码确保安全"
else
    echo ""
    echo -e "${RED}[WARNING]${NC} 部署可能存在问题，请检查失败项"
fi

echo "========================================"

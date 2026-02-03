#!/bin/bash

# ========================================
# 一键部署脚本 - 将修复脚本上传并执行
# ========================================

set -e

# 服务器配置
SERVER_IP="216.128.151.224"
SERVER_USER="root"
SCRIPT_NAME="fix-nginx-monitor.sh"

echo "========================================="
echo "部署并执行 Nginx 修复脚本"
echo "========================================="
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查脚本是否存在
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "❌ 错误: 找不到脚本文件 $SCRIPT_NAME"
    echo "当前目录: $(pwd)"
    exit 1
fi

# 上传脚本到服务器
echo "📤 上传脚本到服务器 $SERVER_IP..."
scp "$SCRIPT_NAME" ${SERVER_USER}@${SERVER_IP}:/tmp/

if [ $? -ne 0 ]; then
    echo "❌ 上传失败,请检查:"
    echo "  1. 服务器IP是否正确: $SERVER_IP"
    echo "  2. SSH密钥是否配置"
    echo "  3. 服务器是否可访问"
    exit 1
fi

echo "✅ 上传成功"
echo ""

# 在服务器上执行脚本
echo "🚀 在服务器上执行修复脚本..."
echo "========================================="
ssh ${SERVER_USER}@${SERVER_IP} "bash /tmp/$SCRIPT_NAME"
echo "========================================="
echo ""

echo "✅ 部署和执行完成!"
echo ""
echo "请访问以下地址验证:"
echo "  • http://$SERVER_IP/"
echo "  • http://$SERVER_IP/monitor/"

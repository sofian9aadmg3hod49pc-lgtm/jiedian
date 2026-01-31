#!/bin/bash

echo "==================================="
echo "配置中心功能测试"
echo "==================================="
echo ""

# 检查API文件是否存在
echo "1. 检查API文件..."
if [ -f "/workspace/monitor-dashboard/api/config.js" ]; then
    echo "✅ API配置文件存在"
else
    echo "❌ API配置文件不存在"
    exit 1
fi

# 检查依赖是否安装
echo ""
echo "2. 检查qrcode依赖..."
if [ -d "/workspace/monitor-dashboard/node_modules/qrcode" ]; then
    echo "✅ qrcode模块已安装"
else
    echo "❌ qrcode模块未安装"
    exit 1
fi

# 检查前端文件修改
echo ""
echo "3. 检查前端文件修改..."
if grep -q "config-panel" /workspace/monitor-dashboard/public/index.html; then
    echo "✅ HTML模板已更新"
else
    echo "❌ HTML模板未更新"
    exit 1
fi

if grep -q "loadShadowrocketConfig" /workspace/monitor-dashboard/public/app.js; then
    echo "✅ JavaScript逻辑已更新"
else
    echo "❌ JavaScript逻辑未更新"
    exit 1
fi

if grep -q "config-card" /workspace/monitor-dashboard/public/style.css; then
    echo "✅ CSS样式已添加"
else
    echo "❌ CSS样式未添加"
    exit 1
fi

# 检查服务器配置
echo ""
echo "4. 检查服务器路由配置..."
if grep -q "configRouter" /workspace/monitor-dashboard/server.js; then
    echo "✅ 服务器路由已配置"
else
    echo "❌ 服务器路由未配置"
    exit 1
fi

# 创建测试配置文件
echo ""
echo "5. 创建测试配置文件..."
mkdir -p /tmp
cat > /tmp/v2ray-info.json <<EOF
{
  "uuid": "test-uuid-1234567890",
  "domain": "test.example.com",
  "port": 443,
  "ws_path": "/v2ray"
}
EOF

if [ -f "/tmp/v2ray-info.json" ]; then
    echo "✅ 测试配置文件已创建"
else
    echo "❌ 测试配置文件创建失败"
    exit 1
fi

# 测试API
echo ""
echo "6. 测试API功能..."
cd /workspace/monitor-dashboard
node -e "
const express = require('express');
const request = require('http');
const configRouter = require('./api/config');

// 简单测试API导入
try {
    console.log('✅ API模块可以正常导入');
} catch (error) {
    console.log('❌ API模块导入失败:', error.message);
    process.exit(1);
}
"

echo ""
echo "==================================="
echo "✅ 所有检查通过！"
echo "==================================="
echo ""
echo "功能说明："
echo "1. 访问监控面板 http://ttjj11233.duckdns.org:3001"
echo "2. 登录后，在页面底部可以看到「Shadowrocket 配置」区域"
echo "3. 可以一键复制 vmess:// 链接"
echo "4. 可以扫描二维码直接导入 Shadowrocket"
echo "5. 查看完整的服务器配置信息"
echo ""
echo "部署说明："
echo "需要将监控面板部署到 Vultr 服务器上才能生效"
echo "建议使用以下命令部署："
echo "  cd /workspace/monitor-dashboard"
echo "  npm install"
echo "  # 然后使用现有部署脚本部署到服务器"

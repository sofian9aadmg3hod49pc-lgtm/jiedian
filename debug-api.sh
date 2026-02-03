#!/bin/bash

# 调试API问题

echo "=== 调试 /api/config 接口 ==="
echo ""

echo "【1. 检查进程状态】"
ps aux | grep "node server.js" | grep -v grep
echo ""

echo "【2. 检查端口监听】"
netstat -tlnp | grep 3001
echo ""

echo "【3. 直接测试API（带认证）】"
curl -v -u admin:v2raymonitor http://localhost:3001/api/config 2>&1 | head -30
echo ""

echo "【4. 检查v2ray-info.json内容】"
cat /tmp/v2ray-info.json
echo ""

echo "【5. 检查server.js中的路由配置】"
grep -n "api/config" /tmp/monitor-dashboard/server.js
echo ""

echo "【6. 查看完整日志】"
tail -50 /tmp/monitor/server.log

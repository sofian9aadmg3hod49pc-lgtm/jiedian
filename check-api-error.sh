#!/bin/bash

# 检查API错误

echo "=== 检查API错误 ==="
echo ""

echo "【1. 服务日志】"
tail -50 /tmp/monitor/server.log
echo ""

echo "【2. 测试API接口】"
curl -s -u admin:v2raymonitor http://localhost:3001/api/config | head -20
echo ""

echo "【3. 检查config.js内容】"
head -30 /tmp/monitor-dashboard/api/config.js
echo ""

echo "【4. 检查node_modules】"
ls /tmp/monitor-dashboard/node_modules/ | grep -E "(express|axios|basic-auth)" | head -10

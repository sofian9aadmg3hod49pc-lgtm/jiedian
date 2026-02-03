#!/bin/bash

# 修复config.js API文件

echo "=== 修复 /api/config 接口 ==="
echo ""

cd /tmp/monitor-dashboard

echo "【1. 检查api目录】"
ls -la api/
echo ""

echo "【2. 从本地复制config.js】"
if [ -f "/root/jiedian/monitor-dashboard/api/config.js" ]; then
    cp /root/jiedian/monitor-dashboard/api/config.js api/
    echo "✅ 已复制 config.js"
elif [ -f "/workspace/monitor-dashboard/api/config.js" ]; then
    cp /workspace/monitor-dashboard/api/config.js api/
    echo "✅ 已复制 config.js"
else
    echo "❌ 找不到源文件"
    find / -name "config.js" -path "*/monitor-dashboard/*" 2>/dev/null | head -3
fi
echo ""

echo "【3. 验证文件】"
ls -la api/config.js
head -5 api/config.js
echo ""

echo "【4. 重启服务】"
pkill -f "node server.js"
sleep 2
nohup node server.js > /tmp/monitor/server.log 2>&1 &
sleep 3
echo ""

echo "【5. 测试API】"
curl -s -u admin:v2raymonitor http://localhost:3001/api/config | head -3

#!/bin/bash

# 检查监控服务状态

echo "=== 监控服务状态检查 ==="
echo ""

echo "【1. 进程状态】"
ps aux | grep "node server.js" | grep -v grep
echo ""

echo "【2. 端口监听】"
netstat -tlnp | grep 3001
echo ""

echo "【3. 本地访问测试】"
curl -s -m 3 http://localhost:3001/ | head -10
echo ""

echo "【4. 服务日志】"
tail -20 /tmp/monitor/server.log 2>/dev/null || echo "日志文件不存在"
echo ""

echo "【5. 防火墙状态】"
ufw status 2>/dev/null || echo "ufw 未安装"
echo ""

echo "【6. iptables 规则】"
iptables -L -n | grep 3001 || echo "无3001相关规则"

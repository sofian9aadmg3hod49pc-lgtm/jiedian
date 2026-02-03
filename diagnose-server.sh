#!/bin/bash

# 服务器诊断脚本
# 在服务器上执行此脚本，将输出保存后发送给开发者

echo "=========================================="
echo "     服务器诊断报告"
echo "     时间: $(date)"
echo "=========================================="
echo ""

echo "【1. 系统信息】"
echo "------------------------------"
uname -a
echo ""

echo "【2. 端口监听状态】"
echo "------------------------------"
echo "--- netstat ---"
netstat -tlnp 2>/dev/null | grep -E "(3001|80|443)" || echo "netstat 未找到或失败"
echo ""
echo "--- ss ---"
ss -tlnp 2>/dev/null | grep -E "(3001|80|443)" || echo "ss 未找到或失败"
echo ""

echo "【3. 进程状态】"
echo "------------------------------"
echo "--- Node.js 进程 ---"
ps aux | grep -E "(node|npm)" | grep -v grep || echo "无 Node.js 进程"
echo ""
echo "--- Nginx 进程 ---"
ps aux | grep nginx | grep -v grep || echo "无 Nginx 进程"
echo ""

echo "【4. 监控面板目录】"
echo "------------------------------"
echo "--- 查找 monitor-dashboard ---"
find / -name "monitor-dashboard" -type d 2>/dev/null | head -5
echo ""

echo "【5. 常见路径检查】"
echo "------------------------------"
PATHS=(
    "/workspace/monitor-dashboard"
    "/var/www/monitor/monitor-dashboard"
    "/root/jiedian/monitor-dashboard"
    "/home/ubuntu/monitor-dashboard"
    "/root/monitor-dashboard"
)
for path in "${PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "✅ 存在: $path"
        if [ -f "$path/server.js" ]; then
            echo "   └─ server.js 存在"
        else
            echo "   └─ server.js 不存在"
        fi
    else
        echo "❌ 不存在: $path"
    fi
done
echo ""

echo "【6. Nginx 配置】"
echo "------------------------------"
if [ -f "/etc/nginx/sites-available/default" ]; then
    echo "--- Nginx 默认配置 ---"
    cat /etc/nginx/sites-available/default | grep -A 10 -B 2 "monitor\|3001" || echo "未找到 monitor/3001 相关配置"
else
    echo "Nginx 配置文件不存在"
fi
echo ""

echo "【7. 日志文件】"
echo "------------------------------"
if [ -f "/tmp/monitor/server.log" ]; then
    echo "--- 监控服务日志 (最后20行) ---"
    tail -20 /tmp/monitor/server.log
else
    echo "日志文件不存在: /tmp/monitor/server.log"
fi
echo ""

echo "【8. 本地测试】"
echo "------------------------------"
echo "--- 测试 localhost:3001 ---"
curl -s -m 3 -I http://localhost:3001/ 2>&1 || echo "无法连接到 localhost:3001"
echo ""

echo "【9. 防火墙状态】"
echo "------------------------------"
if command -v ufw &> /dev/null; then
    ufw status
else
    echo "ufw 未安装"
fi
echo ""

echo "【10. Docker 容器】"
echo "------------------------------"
if command -v docker &> /dev/null; then
    docker ps 2>/dev/null || echo "Docker 未运行或无权限"
else
    echo "Docker 未安装"
fi
echo ""

echo "=========================================="
echo "     诊断完成"
echo "=========================================="

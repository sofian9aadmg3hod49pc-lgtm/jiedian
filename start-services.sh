#!/bin/bash
# 启动监控面板和Nginx服务

echo "=== 启动监控后台服务 ==="

# 1. 启动监控面板
echo "[1/2] 启动监控面板 (端口 3001)..."
cd /workspace/monitor-dashboard

# 检查是否已运行
if pgrep -f "node server.js" > /dev/null; then
    echo "✅ 监控面板已在运行"
else
    nohup node server.js > /tmp/monitor.log 2>&1 &
    sleep 2
    if pgrep -f "node server.js" > /dev/null; then
        echo "✅ 监控面板启动成功"
    else
        echo "❌ 监控面板启动失败"
        cat /tmp/monitor.log
        exit 1
    fi
fi

# 2. 启动Nginx
echo "[2/2] 启动 Nginx (端口 80)..."
if pgrep nginx > /dev/null; then
    echo "✅ Nginx已在运行"
else
    # 确保配置文件正确
    cp /workspace/nginx_config_fixed.conf /etc/nginx/sites-available/default 2>/dev/null || true
    nginx
    sleep 1
    if pgrep nginx > /dev/null; then
        echo "✅ Nginx启动成功"
    else
        echo "❌ Nginx启动失败"
        nginx -t
        exit 1
    fi
fi

# 3. 验证服务
echo ""
echo "=== 服务状态检查 ==="
echo -n "监控面板 (3001): "
ss -tlnp | grep :3001 > /dev/null && echo "✅ 正常" || echo "❌ 异常"

echo -n "Nginx (80): "
ss -tlnp | grep :80 > /dev/null && echo "✅ 正常" || echo "❌ 异常"

echo ""
echo "=== 访问地址 ==="
echo "📌 直接访问: http://$(hostname -I | awk '{print $1}'):3001"
echo "📌 Nginx代理: http://$(hostname -I | awk '{print $1}')/monitor/"
echo ""
echo "🔐 登录凭证"
echo "   用户名: admin"
echo "   密码: v2raymonitor"

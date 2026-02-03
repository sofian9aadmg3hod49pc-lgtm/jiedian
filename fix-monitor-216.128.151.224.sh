#!/bin/bash

# 一键修复监控面板服务
# 服务器IP: 216.128.151.224

set -e

echo "=== V2Ray 监控面板一键修复脚本 ==="
echo "目标服务器: 216.128.151.224"
echo ""

# 查找监控目录
echo "🔍 步骤1: 查找监控面板目录..."
MONITOR_DIRS=$(find / -name "monitor-dashboard" -type d 2>/dev/null | grep -v node_modules | head -3)

if [ -z "$MONITOR_DIRS" ]; then
    echo "❌ 未找到monitor-dashboard目录，尝试常见路径..."
    COMMON_PATHS=(
        "/workspace/monitor-dashboard"
        "/var/www/monitor/monitor-dashboard"
        "/root/jiedian/monitor-dashboard"
        "/home/ubuntu/monitor-dashboard"
        "/root/monitor-dashboard"
    )

    for path in "${COMMON_PATHS[@]}"; do
        if [ -d "$path" ]; then
            MONITOR_DIR="$path"
            break
        fi
    done

    if [ -z "$MONITOR_DIR" ]; then
        echo "❌ 无法找到监控面板目录"
        exit 1
    fi
else
    MONITOR_DIR=$(echo "$MONITOR_DIRS" | head -1)
fi

echo "✅ 找到目录: $MONITOR_DIR"
echo ""

# 检查目录是否存在
if [ ! -d "$MONITOR_DIR" ]; then
    echo "❌ 目录不存在: $MONITOR_DIR"
    exit 1
fi

# 停止旧进程
echo "🛑 步骤2: 停止旧进程..."
pkill -f "node server.js" 2>/dev/null || true
sleep 2
echo "✅ 旧进程已停止"
echo ""

# 进入目录
cd "$MONITOR_DIR"

# 检查关键文件
echo "📋 步骤3: 检查文件完整性..."
if [ ! -f "server.js" ]; then
    echo "❌ 缺少 server.js 文件"
    exit 1
fi

if [ ! -f "public/index.html" ]; then
    echo "❌ 缺少 public/index.html 文件"
    exit 1
fi
echo "✅ 文件完整"
echo ""

# 安装依赖
echo "📦 步骤4: 检查并安装依赖..."
if [ ! -d "node_modules" ] || [ ! -d "node_modules/socket.io" ]; then
    echo "正在安装依赖..."
    npm install
    echo "✅ 依赖安装完成"
else
    echo "✅ 依赖已存在，跳过安装"
fi
echo ""

# 创建日志目录
echo "📁 步骤5: 创建日志目录..."
mkdir -p /tmp/monitor/data
echo "✅ 日志目录创建完成"
echo ""

# 启动服务
echo "🚀 步骤6: 启动监控服务..."
nohup node server.js > /tmp/monitor/server.log 2>&1 &
sleep 4
echo ""

# 验证服务状态
echo "✅ 步骤7: 验证服务状态..."

# 检查进程
if pgrep -f "node server.js" > /dev/null; then
    PROCESS_ID=$(pgrep -f "node server.js")
    echo "✅ 进程运行中 (PID: $PROCESS_ID)"
else
    echo "❌ 进程未启动"
    echo ""
    echo "查看错误日志:"
    cat /tmp/monitor/server.log
    exit 1
fi

# 检查端口
if netstat -tlnp 2>/dev/null | grep ":3001" > /dev/null; then
    echo "✅ 端口3001已监听"
elif command -v ss &> /dev/null && ss -tlnp | grep ":3001" > /dev/null; then
    echo "✅ 端口3001已监听"
else
    echo "⚠️  端口3001未检测到监听，可能正在启动中..."
fi

# 本地测试
echo ""
echo "🔍 步骤8: 本地访问测试..."
if curl -s -m 3 http://localhost:3001/ > /dev/null 2>&1; then
    echo "✅ 本地访问成功"
else
    echo "⚠️  本地访问失败，查看日志:"
    echo "---"
    tail -20 /tmp/monitor/server.log
    echo "---"
fi

echo ""
echo "========================================="
echo "🎉 监控面板修复完成！"
echo "========================================="
echo ""
echo "📊 访问地址:"
echo "  直接访问: http://216.128.151.224:3001/"
echo "  Nginx代理: http://216.128.151.224/monitor/"
echo ""
echo "📋 管理命令:"
echo "  查看日志: tail -f /tmp/monitor/server.log"
echo "  重启服务: cd $MONITOR_DIR && pkill -f 'node server.js' && nohup node server.js > /tmp/monitor/server.log 2>&1 &"
echo "  停止服务: pkill -f 'node server.js'"
echo ""
echo "🔐 默认登录:"
echo "  用户名: admin"
echo "  密码: v2raymonitor"
echo ""

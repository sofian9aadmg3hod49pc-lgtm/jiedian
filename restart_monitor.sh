#!/bin/bash
# 重启监控中心服务脚本

set -e

echo "=== 重启监控中心服务 ==="

# 进入监控目录
cd /workspace/monitor-dashboard

# 检查Node.js环境
if ! command -v node &> /dev/null; then
    echo "错误: Node.js未安装"
    exit 1
fi

# 停止可能存在的旧进程
echo "停止旧进程..."
pkill -f "node server.js" || true

# 等待端口释放
sleep 2

# 安装依赖（如果需要）
if [ ! -d "node_modules" ]; then
    echo "安装依赖..."
    npm install
fi

# 创建数据目录
mkdir -p /tmp/monitor/data

# 启动服务
echo "启动监控服务..."
nohup node server.js > /tmp/monitor/server.log 2>&1 &

# 等待服务启动
sleep 3

# 检查服务状态
if pgrep -f "node server.js" > /dev/null; then
    echo "✓ 监控服务启动成功"
    echo "✓ 进程ID: $(pgrep -f 'node server.js')"
    echo "✓ 日志文件: /tmp/monitor/server.log"
    echo ""
    echo "访问地址:"
    echo "  - http://216.128.151.224:3001/"
    echo "  - http://ttjj11233.duckdns.org:3001/"
    echo ""
    echo "默认账号: admin"
    echo "默认密码: v2raymonitor"
else
    echo "✗ 监控服务启动失败"
    echo "查看日志: tail -f /tmp/monitor/server.log"
    exit 1
fi

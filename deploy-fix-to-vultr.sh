#!/bin/bash

# 快速修复监控面板并部署到Vultr

SERVER_IP="216.128.151.224"
SERVER_PORT="2222"

echo "=== 快速修复监控面板并部署 ==="
echo ""

# 步骤1: 上传修复后的Nginx配置
echo "步骤1: 上传修复后的Nginx配置..."
scp -P $SERVER_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /workspace/nginx_config_fixed.conf root@$SERVER_IP:/tmp/

if [ $? -eq 0 ]; then
    echo "✅ 配置文件上传成功"
else
    echo "❌ 配置文件上传失败"
    exit 1
fi

# 步骤2: 在服务器上应用配置
echo ""
echo "步骤2: 在服务器上应用配置..."
ssh -p $SERVER_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$SERVER_IP << 'ENDSSH'

# 备份当前配置
echo "备份当前配置..."
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S)

# 应用新配置
echo "应用新配置..."
cp /tmp/nginx_config_fixed.conf /etc/nginx/sites-available/default

# 测试配置
echo "测试Nginx配置..."
if nginx -t; then
    echo "✅ 配置测试通过"
    
    # 重载Nginx
    echo "重载Nginx..."
    nginx -s reload
    echo "✅ Nginx已重载"
else
    echo "❌ 配置测试失败，恢复备份"
    cp /etc/nginx/sites-available/default.backup.* /etc/nginx/sites-available/default
    exit 1
fi

# 检查并启动SOCAT
echo ""
echo "检查SOCAT端口转发..."
if ! pgrep -f "socat.*3001" > /dev/null; then
    echo "启动SOCAT端口转发..."
    
    # 停止占用端口的进程
    fuser -k 3001/tcp 2>/dev/null || true
    sleep 1
    
    # 获取容器IP
    CONTAINER_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -q | head -1) 2>/dev/null || echo "172.24.0.2")
    echo "容器IP: $CONTAINER_IP"
    
    # 启动SOCAT
    nohup socat TCP-LISTEN:3001,fork,reuseaddr TCP:$CONTAINER_IP:3001 > /var/log/socat-monitor.log 2>&1 &
    sleep 2
    
    # 验证端口
    if netstat -tlnp | grep 3001 > /dev/null; then
        echo "✅ SOCAT端口转发已启动"
    else
        echo "⚠️ SOCAT端口转发启动失败，请手动检查"
    fi
else
    echo "✅ SOCAT已在运行"
fi

# 验证本地访问
echo ""
echo "验证本地访问..."
if curl -s -m 2 http://localhost:3001 -I | grep -q "HTTP"; then
    echo "✅ 本地端口3001可访问"
else
    echo "⚠️ 本地端口3001不可访问"
fi

ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    echo "=== 部署完成 ==="
    echo ""
    echo "请访问以下地址验证:"
    echo "  http://66.42.124.79/monitor/"
    echo "  http://ttjj11233.duckdns.org/monitor/"
    echo ""
else
    echo ""
    echo "❌ 部署失败，请检查错误信息"
    exit 1
fi

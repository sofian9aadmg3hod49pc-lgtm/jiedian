#!/bin/bash

# ========================================
# 修复 Nginx 反向代理配置 - 方案一
# 目标: 确保监控面板可通过 80 端口访问
# ========================================

set -e

echo "========================================="
echo "开始修复 Nginx 反向代理配置"
echo "========================================="

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  请使用 sudo 权限运行此脚本"
    echo "示例: sudo bash fix-nginx-monitor.sh"
    exit 1
fi

# 备份当前配置
BACKUP_DIR="/etc/nginx/backup"
mkdir -p $BACKUP_DIR
BACKUP_FILE="$BACKUP_DIR/nginx_config_fixed_$(date +%Y%m%d_%H%M%S).conf"

echo "📦 备份当前 Nginx 配置..."
if [ -f /etc/nginx/sites-available/default ]; then
    cp /etc/nginx/sites-available/default "$BACKUP_FILE"
    echo "✅ 备份完成: $BACKUP_FILE"
fi

# 创建新的简化配置
NEW_CONFIG="/etc/nginx/sites-available/monitor"

echo "📝 创建新的 Nginx 配置..."
cat > "$NEW_CONFIG" << 'EOF'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 10M;
    
    # 监控面板主路由
    location / {
        proxy_pass http://127.0.0.1:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }
    
    # API 路由
    location /api/ {
        proxy_pass http://127.0.0.1:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 兼容 /monitor/ 路径
    location ^~ /monitor/ {
        proxy_pass http://127.0.0.1:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "✅ 新配置已创建: $NEW_CONFIG"

# 启用新配置
echo "🔗 启用新配置..."
ln -sf "$NEW_CONFIG" /etc/nginx/sites-enabled/default

# 测试配置
echo "🧪 测试 Nginx 配置..."
if nginx -t; then
    echo "✅ Nginx 配置测试通过"
else
    echo "❌ Nginx 配置测试失败,正在恢复备份..."
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" /etc/nginx/sites-available/default
        systemctl reload nginx
    fi
    exit 1
fi

# 重启 Nginx
echo "🔄 重启 Nginx 服务..."
systemctl restart nginx

# 等待服务启动
sleep 2

# 验证状态
echo "========================================="
echo "验证服务状态"
echo "========================================="

echo ""
echo "📊 Nginx 服务状态:"
systemctl status nginx --no-pager -l | head -n 5

echo ""
echo "🔍 端口监听状态:"
ss -tuln | grep -E ':80|:3001'

echo ""
echo "🌐 测试本地访问:"
curl -I http://localhost 2>&1 | head -n 5

echo ""
echo "========================================="
echo "✅ 修复完成!"
echo "========================================="
echo ""
echo "请测试以下访问地址:"
echo "  • http://216.128.151.224/"
echo "  • http://216.128.151.224/monitor/"
echo ""
echo "如果仍有问题,可恢复备份:"
echo "  sudo cp $BACKUP_FILE /etc/nginx/sites-available/default"
echo "  sudo systemctl restart nginx"
echo ""

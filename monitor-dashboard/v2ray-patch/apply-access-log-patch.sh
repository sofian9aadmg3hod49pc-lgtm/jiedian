#!/bin/bash
#
# V2Ray配置补丁：启用访问日志
#

set -e

V2RAY_CONFIG="/usr/local/etc/v2ray/config.json"
V2RAY_ACCESS_LOG="/var/log/v2ray/access.log"

echo "开始应用V2Ray访问日志配置补丁..."

# 确保日志目录存在
mkdir -p /var/log/v2ray
chown -R nobody:nogroup /var/log/v2ray
chmod 755 /var/log/v2ray

# 备份原始配置
if [ -f "$V2RAY_CONFIG" ]; then
    cp "$V2RAY_CONFIG" "${V2RAY_CONFIG}.backup.$(date +%Y%m%d%H%M%S)"
    echo "已备份原始配置到: ${V2RAY_CONFIG}.backup.$(date +%Y%m%d%H%M%S)"
fi

# 检查并添加访问日志配置
if [ -f "$V2RAY_CONFIG" ]; then
    # 使用jq检查并添加log配置
    if command -v jq &> /dev/null; then
        echo "使用jq更新配置..."
        jq '.log = {
            "access": "/var/log/v2ray/access.log",
            "error": "/var/log/v2ray/error.log",
            "loglevel": "warning"
        }' "$V2RAY_CONFIG" > "${V2RAY_CONFIG}.tmp" && mv "${V2RAY_CONFIG}.tmp" "$V2RAY_CONFIG"
    else
        echo "警告: jq未安装，尝试手动补丁..."
        # 检查是否已有log配置
        if ! grep -q '"log"' "$V2RAY_CONFIG"; then
            # 在文件开头添加log配置
            sed -i '1i\{\n  "log": {\n    "access": "/var/log/v2ray/access.log",\n    "error": "/var/log/v2ray/error.log",\n    "loglevel": "warning"\n  },' "$V2RAY_CONFIG"
        fi
    fi
else
    echo "错误: V2Ray配置文件不存在: $V2RAY_CONFIG"
    exit 1
fi

# 验证JSON格式
if command -v jq &> /dev/null; then
    if ! jq empty "$V2RAY_CONFIG" 2>/dev/null; then
        echo "错误: 配置文件JSON格式无效"
        exit 1
    fi
fi

# 重启V2Ray服务
echo "重启V2Ray服务..."
systemctl restart v2ray

# 等待服务启动
sleep 2

# 验证服务状态
if systemctl is-active --quiet v2ray; then
    echo "✓ V2Ray服务运行正常"
else
    echo "✗ V2Ray服务启动失败"
    systemctl status v2ray
    exit 1
fi

# 验证日志文件生成
sleep 3
if [ -f "$V2RAY_ACCESS_LOG" ]; then
    echo "✓ 访问日志文件已创建: $V2RAY_ACCESS_LOG"
    echo "  文件大小: $(wc -c < "$V2RAY_ACCESS_LOG") 字节"
else
    echo "⚠ 访问日志文件尚未生成（可能还没有流量）"
fi

echo "V2Ray访问日志配置补丁应用完成"

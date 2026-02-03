#!/bin/bash
#
# V2Ray配置补丁：启用详细的流量日志记录
#

set -e

V2RAY_CONFIG="/usr/local/etc/v2ray/config.json"

echo "开始应用V2Ray流量日志补丁..."

# 备份配置
if [ -f "$V2RAY_CONFIG" ]; then
    cp "$V2RAY_CONFIG" "${V2RAY_CONFIG}.backup.$(date +%Y%m%d%H%M%S)"
    echo "已备份配置"
fi

# 检查是否安装jq
if ! command -v jq &> /dev/null; then
    echo "安装jq工具..."
    apt-get update && apt-get install -y jq || yum install -y jq
fi

# 更新日志级别为debug以获取更详细的流量信息
if jq -e '.log.loglevel = "debug"' "$V2RAY_CONFIG" > "${V2RAY_CONFIG}.tmp"; then
    mv "${V2RAY_CONFIG}.tmp" "$V2RAY_CONFIG"
    echo "✓ 日志级别已设置为debug"
fi

# 重启V2Ray
systemctl restart v2ray
sleep 2

if systemctl is-active --quiet v2ray; then
    echo "✓ V2Ray服务已重启"
    echo "流量日志补丁应用完成"
else
    echo "✗ V2Ray服务启动失败"
    exit 1
fi

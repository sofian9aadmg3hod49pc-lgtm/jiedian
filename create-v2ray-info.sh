#!/bin/bash

# 创建 v2ray-info.json 配置文件
# 使用服务器IP作为域名

SERVER_IP="216.128.151.224"

cat > /tmp/v2ray-info.json << EOF
{
    "uuid": "0a06027f-fae2-44cb-9388-37460dc8451e",
    "domain": "${SERVER_IP}",
    "port": "443",
    "ws_path": "/v2ray"
}
EOF

echo "✅ 已创建 /tmp/v2ray-info.json"
cat /tmp/v2ray-info.json

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
V2Ray Shadowrocket 配置生成器
生成vmess://链接和配置文件
"""

import sys
import json
import base64
import os
import hashlib
import uuid
from datetime import datetime


def generate_vmess_link(v2ray_info, domain, port):
    """
    生成vmess://链接
    
    Args:
        v2ray_info: V2Ray配置信息
        domain: 域名
        port: 端口
    
    Returns:
        vmess://链接
    """
    vmess_config = {
        "v": "2",
        "ps": f"V2Ray-{domain}",
        "add": domain,
        "port": str(port),
        "id": v2ray_info["uuid"],
        "aid": "0",
        "net": "ws",
        "type": "none",
        "host": domain,
        "path": v2ray_info["ws_path"],
        "tls": "tls"
    }
    
    # 转换为JSON字符串并base64编码
    vmess_json = json.dumps(vmess_config, separators=(',', ':'))
    vmess_b64 = base64.b64encode(vmess_json.encode('utf-8')).decode('utf-8')
    
    return f"vmess://{vmess_b64}"


def generate_config_file(v2ray_info, domain, port):
    """
    生成Shadowrocket配置文件
    
    Args:
        v2ray_info: V2Ray配置信息
        domain: 域名
        port: 端口
    
    Returns:
        配置字典
    """
    config = {
        "version": 1,
        "remarks": f"V2Ray-{domain}",
        "server": domain,
        "server_port": port,
        "type": "VMess",
        "uuid": v2ray_info["uuid"],
        "alterId": 0,
        "security": "auto",
        "network": "ws",
        "ws-path": v2ray_info["ws_path"],
        "ws-headers": {
            "Host": domain
        },
        "tls": True
    }
    
    return config


def generate_qr_code_text(vmess_link):
    """
    生成二维码文本（使用ASCII字符）
    """
    # 这里返回链接本身，实际应用中可使用qrcode库生成二维码
    return vmess_link


def main():
    if len(sys.argv) < 4:
        print("用法: python3 config-generator.py <v2ray-info.json> <domain> <port>")
        sys.exit(1)
    
    v2ray_info_file = sys.argv[1]
    domain = sys.argv[2]
    port = int(sys.argv[3])
    
    # 读取V2Ray配置信息
    try:
        with open(v2ray_info_file, 'r') as f:
            v2ray_info = json.load(f)
    except Exception as e:
        print(f"读取配置文件失败: {e}")
        sys.exit(1)
    
    # 生成vmess://链接
    vmess_link = generate_vmess_link(v2ray_info, domain, port)
    
    # 生成配置文件
    config = generate_config_file(v2ray_info, domain, port)
    
    # 保存配置文件
    output_dir = "/tmp"
    config_file = os.path.join(output_dir, "shadowrocket-config.json")
    url_file = os.path.join(output_dir, "shadowrocket-url.txt")
    
    # 保存JSON配置
    with open(config_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    # 保存vmess://链接
    with open(url_file, 'w') as f:
        f.write(vmess_link + "\n")
    
    # 输出结果
    print("\n" + "="*60)
    print("Shadowrocket 配置生成完成")
    print("="*60)
    print(f"\n服务器信息:")
    print(f"  域名: {domain}")
    print(f"  端口: {port}")
    print(f"  UUID: {v2ray_info['uuid']}")
    print(f"  WebSocket路径: {v2ray_info['ws_path']}")
    print(f"  传输协议: WebSocket + TLS")
    
    print(f"\n配置文件已保存:")
    print(f"  {config_file}")
    print(f"  {url_file}")
    
    print(f"\nVMess链接:")
    print(f"  {vmess_link}")
    print("\n使用方法:")
    print("  1. 复制上面的vmess://链接")
    print("  2. 在Shadowrocket中点击 + -> 类型选择VMess")
    print("  3. 粘贴链接，点击保存")
    print("  4. 启用配置并测试连接")
    print("\n" + "="*60)


if __name__ == "__main__":
    main()

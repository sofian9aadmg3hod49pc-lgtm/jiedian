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
    verify_file = os.path.join(output_dir, "verify-config.sh")  # 新增验证脚本
    
    # 保存JSON配置
    with open(config_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    # 保存vmess://链接
    with open(url_file, 'w') as f:
        f.write(vmess_link + "\n")
    
    # 生成验证脚本
    uuid_val = v2ray_info['uuid']
    verify_script = f'''#!/bin/bash
# 配置验证脚本
echo "=========================================="
echo "配置验证工具"
echo "=========================================="
echo ""
echo "服务器信息："
echo "  地址: {domain}"
echo "  端口: {port}"
echo "  路径: /v2ray"
echo "  TLS: 开启"
echo ""
echo "UUID验证："
echo "  完整UUID: {uuid_val}"
echo "  分段显示: {uuid_val[0:8]}-{uuid_val[9:13]}-{uuid_val[14:18]}-{uuid_val[19:23]}-{uuid_val[24:36]}"
echo "  后12位: {uuid_val[-12:]}"
echo ""
echo "验证方法："
echo "  1. 在Shadowrocket中手动输入以上信息"
echo "  2. 或者使用配置文件导入"
echo "=========================================="
'''
    
    with open(verify_file, 'w') as f:
        f.write(verify_script)
    os.chmod(verify_file, 0o755)
    
    # 输出结果
    print("\n" + "="*60)
    print("Shadowrocket 配置生成完成（增强版）")
    print("="*60)
    print(f"\n服务器信息:")
    print(f"  域名: {domain}")
    print(f"  端口: {port}")
    print(f"  UUID: {v2ray_info['uuid']}")
    print(f"  WebSocket路径: {v2ray_info['ws_path']}")
    print(f"  传输协议: WebSocket + TLS")
    
    # 显示UUID校验信息
    print(f"\nUUID校验信息:")
    print(f"  完整: {uuid_val}")
    print(f"  分段: {uuid_val[0:8]}-{uuid_val[9:13]}-{uuid_val[14:18]}")
    print(f"  校验: 请确保扫描后与上方一致")
    
    print(f"\n配置文件已保存:")
    print(f"  {config_file}")
    print(f"  {url_file}")
    print(f"  {verify_file} (验证脚本)")
    
    print(f"\nVMess链接:")
    print(f"  {vmess_link}")
    print("\n推荐导入方法（按可靠性排序）:")
    print("  1. 配置文件导入: 下载 {config_file}，在Shadowrocket中导入")
    print("  2. 手动配置: 按照验证脚本中的信息手动输入")
    print("  3. 二维码扫描: 扫描时仔细核对UUID")
    print("\n" + "="*60)


if __name__ == "__main__":
    main()

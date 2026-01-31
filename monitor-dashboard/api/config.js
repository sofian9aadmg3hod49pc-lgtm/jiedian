const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const qrcode = require('qrcode');

// 获取Shadowrocket配置
router.get('/', async (req, res) => {
    try {
        const configPath = '/tmp/v2ray-info.json';
        
        if (!fs.existsSync(configPath)) {
            return res.status(404).json({ 
                success: false, 
                message: 'V2Ray配置文件不存在，请先运行部署脚本' 
            });
        }
        
        // 读取V2Ray配置
        const configData = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        const { uuid, domain, port, ws_path } = configData;
        
        // 生成vmess://链接
        const vmessConfig = {
            "v": "2",
            "ps": `V2Ray-${domain}`,
            "add": domain,
            "port": String(port),
            "id": uuid,
            "aid": "0",
            "net": "ws",
            "type": "none",
            "host": domain,
            "path": ws_path,
            "tls": "tls"
        };
        
        const vmessJson = JSON.stringify(vmessConfig, null, 0);
        const vmessBase64 = Buffer.from(vmessJson).toString('base64');
        const vmessLink = `vmess://${vmessBase64}`;
        
        // 生成二维码
        const qrCodeDataUrl = await qrcode.toDataURL(vmessLink);
        
        // 返回完整配置数据
        res.json({
            success: true,
            data: {
                vmessLink,
                qrCode: qrCodeDataUrl,
                serverInfo: {
                    domain,
                    port,
                    uuid,
                    ws_path,
                    protocol: "VMess + WebSocket + TLS"
                },
                instructions: {
                    ios: "1. 复制vmess://链接或扫描二维码\n2. 打开Shadowrocket\n3. 点击+ → 类型选择VMess\n4. 粘贴链接，点击保存",
                    android: "1. 复制vmess://链接\n2. 打开V2RayNG客户端\n3. 点击+ → 从剪贴板导入"
                }
            }
        });
        
    } catch (error) {
        console.error('读取V2Ray配置失败:', error);
        res.status(500).json({ 
            success: false, 
            message: '读取配置失败', 
            error: error.message 
        });
    }
});

module.exports = router;

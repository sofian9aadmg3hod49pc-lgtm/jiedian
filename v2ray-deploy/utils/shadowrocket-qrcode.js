#!/usr/bin/env node
/**
 * Shadowrocket 二维码生成器 - 修复版
 * 增加错误纠正级别，提高扫描识别率
 */

const qrcode = require('qrcode');
const fs = require('fs');

// 从命令行参数读取vmess链接
const vmessLink = process.argv[2];

if (!vmessLink) {
    console.error('Usage: node shadowrocket-qrcode.js <vmess://link>');
    process.exit(1);
}

// 生成二维码 - 修复：增加错误纠正级别
qrcode.toString(vmessLink, {
    type: 'terminal',
    width: 60,  // 增加宽度，提高清晰度
    errorCorrectionLevel: 'H',  // 高错误纠正级别（可恢复30%错误）
    margin: 3  // 增加边距
}, (err, url) => {
    if (err) {
        console.error('生成二维码失败:', err);
        process.exit(1);
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('Shadowrocket 二维码（高容错版）');
    console.log('='.repeat(60) + '\n');
    console.log(url);
    console.log('\n' + '='.repeat(60));
    console.log('重要：请核对以下关键字段');
    console.log('='.repeat(60));
    
    // 从vmess链接提取并显示关键信息
    try {
        const base64Data = vmessLink.replace('vmess://', '');
        const jsonStr = Buffer.from(base64Data, 'base64').toString('utf-8');
        const config = JSON.parse(jsonStr);
        
        console.log(`服务器地址: ${config.add}`);
        console.log(`端口: ${config.port}`);
        console.log(`UUID: ${config.id}`);
        console.log(`路径: ${config.path}`);
        console.log(`TLS: ${config.tls}`);
        
        // 显示UUID校验信息
        const uuid = config.id;
        console.log('\nUUID校验:');
        console.log(`  完整: ${uuid}`);
        console.log(`  分段: ${uuid.substring(0, 8)}-${uuid.substring(9, 13)}-${uuid.substring(14, 18)}`);
        console.log(`  后8位: ${uuid.substring(uuid.length - 12)}`);
        
    } catch (e) {
        console.log('配置解析失败，请手动验证');
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('vmess://链接:');
    console.log(vmessLink);
    console.log('='.repeat(60) + '\n');
});

// 保存为图片文件 - 修复：提高图片质量
qrcode.toFile('/tmp/shadowrocket-qrcode.png', vmessLink, {
    width: 400,  // 增加宽度
    margin: 4,   // 增加边距
    errorCorrectionLevel: 'H',  // 高错误纠正级别
    color: {
        dark: '#000000',  // 纯黑色
        light: '#FFFFFF'  // 纯白色
    }
}, (err) => {
    if (err) {
        console.error('保存二维码图片失败:', err);
    } else {
        console.log('二维码已保存到: /tmp/shadowrocket-qrcode.png');
        console.log('提示：图片二维码比终端二维码识别率更高');
    }
});

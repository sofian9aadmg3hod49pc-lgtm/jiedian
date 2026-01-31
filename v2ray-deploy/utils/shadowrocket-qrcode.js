#!/usr/bin/env node
/**
 * Shadowrocket 二维码生成器
 * 生成vmess://链接的二维码
 */

const qrcode = require('qrcode');
const fs = require('fs');

// 从命令行参数读取vmess链接
const vmessLink = process.argv[2];

if (!vmessLink) {
    console.error('Usage: node shadowrocket-qrcode.js <vmess://link>');
    process.exit(1);
}

// 生成二维码
qrcode.toString(vmessLink, {
    type: 'terminal',
    width: 40
}, (err, url) => {
    if (err) {
        console.error('生成二维码失败:', err);
        process.exit(1);
    }
    
    console.log('\n========================================');
    console.log('Shadowrocket 二维码');
    console.log('========================================\n');
    console.log(url);
    console.log('\n========================================');
    console.log('vmess://链接:');
    console.log(vmessLink);
    console.log('========================================\n');
});

// 保存为图片文件
qrcode.toFile('/tmp/shadowrocket-qrcode.png', vmessLink, {
    width: 300,
    margin: 2
}, (err) => {
    if (err) {
        console.error('保存二维码图片失败:', err);
    } else {
        console.log('二维码已保存到: /tmp/shadowrocket-qrcode.png');
    }
});

#!/usr/bin/env node
/**
 * V2Ray 日志数据收集器
 * 增量解析V2Ray access.log，统计连接数和流量
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = '/tmp/monitor/data';
const STATS_FILE = path.join(DATA_DIR, 'stats.json');
const DEVICES_FILE = path.join(DATA_DIR, 'devices.json');
const POSITION_FILE = path.join(DATA_DIR, 'log-position.txt');
const V2RAY_ACCESS_LOG = '/var/log/v2ray/access.log';

// 确保数据目录存在
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

// 读取上次处理到的日志位置
function getLastPosition() {
    try {
        if (fs.existsSync(POSITION_FILE)) {
            const pos = fs.readFileSync(POSITION_FILE, 'utf8');
            return parseInt(pos.trim());
        }
    } catch (error) {
        console.error('读取日志位置失败:', error);
    }
    return 0;
}

// 保存当前处理位置
function savePosition(position) {
    try {
        fs.writeFileSync(POSITION_FILE, position.toString());
    } catch (error) {
        console.error('保存日志位置失败:', error);
    }
}

// 解析单条V2Ray日志
function parseLogLine(line) {
    try {
        const match = line.match(/^(\S+)\s+\[(.+?)\]\s+(\S+)\s+\[(.+?)\]\s+\[(.+?)\]\s+(.+)$/);
        if (!match) return null;

        return {
            date: match[1],
            timestamp: match[2],
            type: match[3],
            target: match[4],
            email: match[5],
            extra: match[6]
        };
    } catch (error) {
        return null;
    }
}

// 从日志行中提取设备ID（从email字段）
function extractDeviceId(logEntry) {
    if (!logEntry || !logEntry.email) return null;

    // 尝试从email中提取设备标识
    const email = logEntry.email;
    
    // 如果email包含UUID格式的设备ID
    const uuidMatch = email.match(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/i);
    if (uuidMatch) return uuidMatch[1];
    
    // 或者使用整个email作为设备标识
    return email;
}

// 从JSON字符串中提取流量数据
function extractTrafficData(jsonStr) {
    try {
        const data = JSON.parse(jsonStr);
        return {
            upload: data.net || data.uplink || 0,
            download: data.net || data.downlink || 0
        };
    } catch (error) {
        return { upload: 0, download: 0 };
    }
}

// 增量解析V2Ray日志
function parseV2RayLog() {
    try {
        if (!fs.existsSync(V2RAY_ACCESS_LOG)) {
            console.log('V2Ray访问日志不存在:', V2RAY_ACCESS_LOG);
            return null;
        }

        const lastPos = getLastPosition();
        const stat = fs.statSync(V2RAY_ACCESS_LOG);
        
        // 如果日志文件被截断，从头开始
        if (stat.size < lastPos) {
            console.log('检测到日志文件被截断，重新开始处理');
            savePosition(0);
        }

        // 读取新的日志内容
        const content = fs.readFileSync(V2RAY_ACCESS_LOG, 'utf8');
        const newLines = content.slice(lastPos).split('\n').filter(line => line.trim());
        
        if (newLines.length === 0) {
            return { linesProcessed: 0, activeConnections: {}, devices: {} };
        }

        // 统计数据
        const activeConnections = {};
        const devices = {};
        let totalUpload = 0;
        let totalDownload = 0;
        let linesProcessed = 0;

        newLines.forEach(line => {
            const entry = parseLogLine(line);
            if (!entry) return;

            linesProcessed++;

            // 提取设备ID
            const deviceId = extractDeviceId(entry);
            if (!deviceId) return;

            // 统计活跃连接
            if (entry.type === 'tcp' || entry.type === 'udp') {
                if (!activeConnections[deviceId]) {
                    activeConnections[deviceId] = 0;
                }
                activeConnections[deviceId]++;
            }

            // 提取流量数据
            const traffic = extractTrafficData(entry.extra);
            if (traffic.upload > 0 || traffic.download > 0) {
                if (!devices[deviceId]) {
                    devices[deviceId] = {
                        id: deviceId,
                        email: entry.email,
                        upload: 0,
                        download: 0,
                        lastSeen: Date.now()
                    };
                }
                
                devices[deviceId].upload += traffic.upload;
                devices[deviceId].download += traffic.download;
                devices[deviceId].lastSeen = Date.now();
                
                totalUpload += traffic.upload;
                totalDownload += traffic.download;
            }
        });

        // 更新处理位置
        savePosition(lastPos + content.slice(lastPos).length);

        return {
            linesProcessed,
            activeConnections,
            devices,
            traffic: { upload: totalUpload, download: totalDownload }
        };
    } catch (error) {
        console.error('解析V2Ray日志失败:', error);
        return null;
    }
}

// 读取现有统计数据
function readStats() {
    try {
        if (fs.existsSync(STATS_FILE)) {
            return JSON.parse(fs.readFileSync(STATS_FILE, 'utf8'));
        }
    } catch (error) {
        console.error('读取统计数据失败:', error);
    }
    return null;
}

// 保存统计数据
function saveStats(stats) {
    try {
        fs.writeFileSync(STATS_FILE, JSON.stringify(stats, null, 2));
    } catch (error) {
        console.error('保存统计数据失败:', error);
    }
}

// 读取现有设备列表
function readDevices() {
    try {
        if (fs.existsSync(DEVICES_FILE)) {
            return JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf8'));
        }
    } catch (error) {
        console.error('读取设备列表失败:', error);
    }
    return [];
}

// 保存设备列表
function saveDevices(devices) {
    try {
        fs.writeFileSync(DEVICES_FILE, JSON.stringify(devices, null, 2));
    } catch (error) {
        console.error('保存设备列表失败:', error);
    }
}

// 主收集函数
function collect() {
    console.log('开始收集V2Ray统计数据...');
    
    const result = parseV2RayLog();
    if (!result) {
        console.log('没有新数据');
        return;
    }

    // 合并现有统计数据
    const existingStats = readStats() || {};
    const existingDevices = readDevices() || [];
    const existingDevicesMap = new Map(existingDevices.map(d => [d.id, d]));

    // 更新流量统计（累加）
    const currentTraffic = {
        upload: (existingStats.upload || 0) + (result.traffic?.upload || 0),
        download: (existingStats.download || 0) + (result.traffic?.download || 0),
        total: (existingStats.upload || 0) + (existingStats.download || 0) + 
               (result.traffic?.upload || 0) + (result.traffic?.download || 0)
    };

    // 更新设备列表（合并或更新）
    const updatedDevices = [];
    const resultDeviceIds = Object.keys(result.devices || {});
    
    // 添加或更新当前检测到的设备
    resultDeviceIds.forEach(deviceId => {
        const newDevice = result.devices[deviceId];
        const existingDevice = existingDevicesMap.get(deviceId);
        
        if (existingDevice) {
            // 累加流量
            updatedDevices.push({
                ...existingDevice,
                upload: existingDevice.upload + newDevice.upload,
                download: existingDevice.download + newDevice.download,
                lastSeen: Math.max(existingDevice.lastSeen, newDevice.lastSeen)
            });
        } else {
            updatedDevices.push(newDevice);
        }
    });

    // 保留最近活跃的设备（30分钟内有活动）
    const thirtyMinutesAgo = Date.now() - 30 * 60 * 1000;
    existingDevices.forEach(device => {
        if (!resultDeviceIds.includes(device.id) && device.lastSeen > thirtyMinutesAgo) {
            updatedDevices.push(device);
        }
    });

    // 计算当前活跃连接数（唯一设备数）
    const activeConnections = Object.keys(result.activeConnections || {}).length;

    // 构建最终统计数据
    const stats = {
        timestamp: Date.now(),
        connections: activeConnections,
        traffic: currentTraffic,
        devices: updatedDevices.length,
        lastUpdate: new Date().toISOString()
    };

    // 保存数据
    saveStats(stats);
    saveDevices(updatedDevices);

    console.log(`收集完成: 处理 ${result.linesProcessed} 条日志, 活跃连接 ${activeConnections}, 设备 ${updatedDevices.length}`);
    console.log(`流量统计: 上传 ${formatBytes(currentTraffic.upload)}, 下载 ${formatBytes(currentTraffic.download)}`);
}

// 格式化字节数
function formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// 执行收集
collect();

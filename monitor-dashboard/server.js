#!/usr/bin/env node
/**
 * V2Ray 监控服务器
 * 提供实时监控数据和Web界面
 */

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const fs = require('fs');
const path = require('path');
const os = require('os');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

const PORT = process.env.MONITOR_PORT || 3001;
const DATA_FILE = '/tmp/monitor/data/stats.json';

// 基础认证
const basicAuth = require('express-basic-auth');
const auth = basicAuth({
    users: { 'admin': process.env.MONITOR_PASSWORD || 'v2raymonitor' },
    challenge: true
});

// 中间件
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// API路由
const statsRouter = require('./api/stats');
const devicesRouter = require('./api/devices');
const systemRouter = require('./api/system');
const configRouter = require('./api/config');

app.get('/', auth, (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});
app.get('/index.html', auth, (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.use('/api', auth);
app.use('/api/stats', statsRouter);
app.use('/api/devices', devicesRouter);
app.use('/api/system', systemRouter);
app.use('/api/config', configRouter);

// 实时数据推送
setInterval(() => {
    io.emit('stats', getRealTimeStats());
}, 5000);

// Socket.io连接处理
io.on('connection', (socket) => {
    console.log('新客户端连接:', socket.id);
    
    // 发送初始数据
    socket.emit('stats', getRealTimeStats());
    
    socket.on('disconnect', () => {
        console.log('客户端断开连接:', socket.id);
    });
});

// 获取实时统计数据
function getRealTimeStats() {
    return {
        timestamp: Date.now(),
        connections: getCurrentConnections(),
        traffic: getTrafficStats(),
        system: getSystemStats()
    };
}

// 获取当前连接数（从collector生成的stats.json读取）
function getCurrentConnections() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
            return data.connections || 0;
        }
        return 0;
    } catch (error) {
        console.error('读取连接数失败:', error);
        return 0;
    }
}

// 获取流量统计（从collector生成的stats.json读取）
function getTrafficStats() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
            if (data.traffic) {
                return {
                    upload: data.traffic.upload || 0,
                    download: data.traffic.download || 0,
                    total: data.traffic.total || ((data.traffic.upload || 0) + (data.traffic.download || 0))
                };
            }
        }
    } catch (error) {
        console.error('读取流量数据失败:', error);
    }
    return { upload: 0, download: 0, total: 0 };
}

// 获取系统状态
function getSystemStats() {
    const cpus = os.cpus();
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    
    return {
        cpu: {
            usage: calculateCPUUsage(cpus),
            cores: cpus.length
        },
        memory: {
            total: totalMem,
            used: totalMem - freeMem,
            free: freeMem,
            usage: ((totalMem - freeMem) / totalMem * 100).toFixed(2)
        },
        uptime: os.uptime(),
        platform: os.platform(),
        arch: os.arch()
    };
}

// 计算CPU使用率
function calculateCPUUsage(cpus) {
    let totalIdle = 0;
    let totalTick = 0;
    
    cpus.forEach(cpu => {
        for (const type in cpu.times) {
            totalTick += cpu.times[type];
        }
        totalIdle += cpu.times.idle;
    });
    
    const idle = totalIdle / cpus.length;
    const total = totalTick / cpus.length;
    
    return (100 - ~~(100 * idle / total)).toFixed(2);
}

// 注意: 不再使用saveStats()和定时任务保存数据
// 数据由v2ray-stats-collector通过systemd定时器每分钟更新

// 启动服务器
server.listen(PORT, '0.0.0.0', () => {
    console.log(`V2Ray监控服务器运行在端口 ${PORT}`);
    console.log(`访问地址: http://0.0.0.0:${PORT}`);
    console.log(`默认用户名: admin`);
    console.log(`默认密码: ${process.env.MONITOR_PASSWORD || 'v2raymonitor'}`);
});

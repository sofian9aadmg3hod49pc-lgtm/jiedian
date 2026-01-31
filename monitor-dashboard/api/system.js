/**
 * 系统状态API
 */

const express = require('express');
const router = express.Router();
const os = require('os');

// 获取系统信息
router.get('/', (req, res) => {
    try {
        const cpus = os.cpus();
        const totalMem = os.totalmem();
        const freeMem = os.freemem();
        
        const systemInfo = {
            hostname: os.hostname(),
            platform: os.platform(),
            arch: os.arch(),
            release: os.release(),
            uptime: os.uptime(),
            cpu: {
                model: cpus[0].model,
                cores: cpus.length,
                usage: calculateCPUUsage(cpus)
            },
            memory: {
                total: totalMem,
                used: totalMem - freeMem,
                free: freeMem,
                usage: ((totalMem - freeMem) / totalMem * 100).toFixed(2)
            },
            network: getNetworkInterfaces(),
            loadavg: os.loadavg()
        };
        
        res.json(systemInfo);
    } catch (error) {
        res.status(500).json({ error: '获取系统信息失败' });
    }
});

// 获取V2Ray服务状态
router.get('/v2ray', (req, res) => {
    const { exec } = require('child_process');
    
    exec('systemctl status v2ray', (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ 
                status: 'stopped',
                error: stderr 
            });
        }
        
        const isRunning = stdout.includes('active (running)');
        res.json({
            status: isRunning ? 'running' : 'stopped',
            pid: extractPid(stdout),
            uptime: extractUptime(stdout)
        });
    });
});

// 重启V2Ray服务
router.post('/v2ray/restart', (req, res) => {
    const { exec } = require('child_process');
    
    exec('systemctl restart v2ray', (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ 
                success: false,
                error: stderr 
            });
        }
        
        res.json({ 
            success: true,
            message: 'V2Ray服务已重启' 
        });
    });
});

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

// 获取网络接口
function getNetworkInterfaces() {
    const interfaces = os.networkInterfaces();
    const result = {};
    
    for (const name in interfaces) {
        const ipv4 = interfaces[name].find(iface => 
            iface.family === 'IPv4' && !iface.internal
        );
        
        if (ipv4) {
            result[name] = {
                address: ipv4.address,
                netmask: ipv4.netmask,
                mac: ipv4.mac
            };
        }
    }
    
    return result;
}

// 从系统状态中提取PID
function extractPid(output) {
    const match = output.match(/Main PID: (\d+)/);
    return match ? match[1] : null;
}

// 从系统状态中提取运行时间
function extractUptime(output) {
    const match = output.match(/active \(running\) since (.?)/);
    return match ? match[1] : null;
}

module.exports = router;

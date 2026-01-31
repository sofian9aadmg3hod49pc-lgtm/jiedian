/**
 * 设备管理API
 */

const express = require('express');
const router = express.Router();
const fs = require('fs');

const DEVICES_FILE = '/tmp/monitor/data/devices.json';

// 获取所有设备
router.get('/', (req, res) => {
    try {
        if (fs.existsSync(DEVICES_FILE)) {
            const devices = JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf8'));
            res.json(devices);
        } else {
            res.json([]);
        }
    } catch (error) {
        res.status(500).json({ error: '读取设备列表失败' });
    }
});

// 添加新设备
router.post('/', (req, res) => {
    try {
        const { name, ip, type } = req.body;
        
        let devices = [];
        if (fs.existsSync(DEVICES_FILE)) {
            devices = JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf8'));
        }
        
        // 检查设备是否已存在
        const existingDevice = devices.find(d => d.ip === ip);
        if (existingDevice) {
            // 更新现有设备
            existingDevice.name = name || existingDevice.name;
            existingDevice.type = type || existingDevice.type;
            existingDevice.online = true;
            existingDevice.last_seen = Date.now();
        } else {
            // 添加新设备
            devices.push({
                id: Date.now(),
                name: name || `Device ${devices.length + 1}`,
                ip,
                type: type || 'Unknown',
                online: true,
                connected_at: new Date().toISOString(),
                last_seen: Date.now()
            });
        }
        
        const dir = '/tmp/monitor/data';
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        
        fs.writeFileSync(DEVICES_FILE, JSON.stringify(devices, null, 2));
        res.json({ message: '设备已添加', device: devices[devices.length - 1] });
    } catch (error) {
        res.status(500).json({ error: '添加设备失败' });
    }
});

// 更新设备状态
router.put('/:id', (req, res) => {
    try {
        const { id } = req.params;
        const { online } = req.body;
        
        if (!fs.existsSync(DEVICES_FILE)) {
            return res.status(404).json({ error: '设备列表不存在' });
        }
        
        const devices = JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf8'));
        const device = devices.find(d => d.id === parseInt(id));
        
        if (!device) {
            return res.status(404).json({ error: '设备不存在' });
        }
        
        device.online = online !== undefined ? online : true;
        device.last_seen = Date.now();
        
        fs.writeFileSync(DEVICES_FILE, JSON.stringify(devices, null, 2));
        res.json({ message: '设备状态已更新', device });
    } catch (error) {
        res.status(500).json({ error: '更新设备状态失败' });
    }
});

// 删除设备
router.delete('/:id', (req, res) => {
    try {
        const { id } = req.params;
        
        if (!fs.existsSync(DEVICES_FILE)) {
            return res.status(404).json({ error: '设备列表不存在' });
        }
        
        let devices = JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf8'));
        const filteredDevices = devices.filter(d => d.id !== parseInt(id));
        
        if (devices.length === filteredDevices.length) {
            return res.status(404).json({ error: '设备不存在' });
        }
        
        fs.writeFileSync(DEVICES_FILE, JSON.stringify(filteredDevices, null, 2));
        res.json({ message: '设备已删除' });
    } catch (error) {
        res.status(500).json({ error: '删除设备失败' });
    }
});

module.exports = router;

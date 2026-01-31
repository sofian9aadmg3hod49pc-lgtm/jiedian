/**
 * V2Ray统计数据API
 */

const express = require('express');
const router = express.Router();
const fs = require('fs');

const DATA_FILE = '/tmp/monitor/data/stats.json';

// 获取当前统计数据
router.get('/', (req, res) => {
    try {
        if (fs.existsSync(DATA_FILE)) {
            const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
            res.json(data);
        } else {
            res.json({
                timestamp: Date.now(),
                connections: 0,
                traffic: {
                    upload: 0,
                    download: 0,
                    total: 0
                },
                system: {
                    cpu: { usage: 0, cores: 0 },
                    memory: { usage: 0, used: 0, free: 0, total: 0 }
                }
            });
        }
    } catch (error) {
        res.status(500).json({ error: '读取统计数据失败' });
    }
});

// 获取历史统计数据
router.get('/history', (req, res) => {
    const { hours = 24 } = req.query;
    const startTime = Date.now() - hours * 60 * 60 * 1000;
    
    try {
        // 这里应该从数据库或文件中读取历史数据
        // 简化实现，返回空数组
        res.json({
            startTime,
            endTime: Date.now(),
            data: []
        });
    } catch (error) {
        res.status(500).json({ error: '读取历史数据失败' });
    }
});

// 重置统计数据
router.post('/reset', (req, res) => {
    try {
        const resetData = {
            timestamp: Date.now(),
            connections: 0,
            traffic: {
                upload: 0,
                download: 0,
                total: 0
            },
            system: {
                cpu: { usage: 0, cores: 0 },
                memory: { usage: 0, used: 0, free: 0, total: 0 }
            }
        };
        
        const dir = '/tmp/monitor/data';
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        
        fs.writeFileSync(DATA_FILE, JSON.stringify(resetData, null, 2));
        res.json({ message: '统计数据已重置', data: resetData });
    } catch (error) {
        res.status(500).json({ error: '重置统计数据失败' });
    }
});

module.exports = router;

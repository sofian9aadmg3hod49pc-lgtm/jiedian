// V2Ray监控面板 - 前端逻辑

const socket = io();
let connectionHistory = [];
const maxHistoryPoints = 24;

// 格式化流量
function formatTraffic(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// 格式化运行时间
function formatUptime(seconds) {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${days} 天 ${hours} 小时 ${minutes} 分钟`;
}

// 更新服务器信息
function updateServerInfo() {
    document.getElementById('last-update').textContent = 
        '最后更新: ' + new Date().toLocaleString('zh-CN');
}

// 更新统计数据
function updateStats(stats) {
    if (!stats) return;
    
    // 更新连接数
    document.getElementById('connections').textContent = stats.connections || 0;
    
    // 更新流量
    const traffic = stats.traffic || {};
    document.getElementById('upload').textContent = formatTraffic(traffic.upload || 0);
    document.getElementById('download').textContent = formatTraffic(traffic.download || 0);
    document.getElementById('total-traffic').textContent = formatTraffic(traffic.total || 0);
    
    // 更新系统状态
    const system = stats.system || {};
    const cpuUsage = system.cpu?.usage || 0;
    const memoryUsage = system.memory?.usage || 0;
    
    const cpuProgress = document.getElementById('cpu-usage');
    cpuProgress.style.width = cpuUsage + '%';
    cpuProgress.textContent = cpuUsage + '%';
    
    // 根据CPU使用率设置颜色
    if (cpuUsage > 80) {
        cpuProgress.style.background = 'linear-gradient(90deg, #F44336 0%, #FF9800 100%)';
    } else if (cpuUsage > 50) {
        cpuProgress.style.background = 'linear-gradient(90deg, #FF9800 0%, #FFC107 100%)';
    } else {
        cpuProgress.style.background = 'linear-gradient(90deg, #4CAF50 0%, #8BC34A 100%)';
    }
    
    const memProgress = document.getElementById('memory-usage');
    memProgress.style.width = memoryUsage + '%';
    memProgress.textContent = memoryUsage + '%';
    
    // 更新内存信息
    if (system.memory) {
        document.getElementById('memory-used').textContent = 
            (system.memory.used / 1024 / 1024 / 1024).toFixed(2) + ' GB';
        document.getElementById('memory-total').textContent = 
            (system.memory.total / 1024 / 1024 / 1024).toFixed(2) + ' GB';
    }
    
    // 更新运行时间
    document.getElementById('uptime').textContent = formatUptime(system.uptime || 0);
    
    // 更新服务器IP（模拟）
    fetch('/api/system')
        .then(res => res.json())
        .then(data => {
            if (data.ip) {
                document.getElementById('server-ip').textContent = '服务器: ' + data.ip;
            }
        })
        .catch(err => {
            console.error('获取服务器信息失败:', err);
        });
}

// 更新连接历史
function updateConnectionHistory(connections) {
    connectionHistory.push({
        timestamp: Date.now(),
        connections: connections
    });
    
    // 限制历史记录数量
    if (connectionHistory.length > maxHistoryPoints) {
        connectionHistory.shift();
    }
    
    // 这里可以添加图表渲染逻辑
    drawChart();
}

// 绘制图表（简化版）
function drawChart() {
    const canvas = document.getElementById('connection-chart');
    const ctx = canvas.getContext('2d');
    
    // 清空画布
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // 设置画布尺寸
    canvas.width = canvas.parentElement.offsetWidth;
    canvas.height = canvas.parentElement.offsetHeight;
    
    if (connectionHistory.length < 2) {
        ctx.fillStyle = '#999';
        ctx.font = '16px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('等待数据...', canvas.width / 2, canvas.height / 2);
        return;
    }
    
    const padding = 40;
    const width = canvas.width - padding * 2;
    const height = canvas.height - padding * 2;
    
    // 找出最大值
    const maxConnections = Math.max(...connectionHistory.map(h => h.connections), 1);
    
    // 绘制网格线
    ctx.strokeStyle = '#e0e0e0';
    ctx.lineWidth = 1;
    
    for (let i = 0; i <= 4; i++) {
        const y = padding + (height / 4) * i;
        ctx.beginPath();
        ctx.moveTo(padding, y);
        ctx.lineTo(padding + width, y);
        ctx.stroke();
        
        // Y轴标签
        ctx.fillStyle = '#666';
        ctx.font = '12px Arial';
        ctx.textAlign = 'right';
        ctx.fillText(Math.round(maxConnections * (1 - i / 4)), padding - 10, y + 4);
    }
    
    // 绘制数据线
    ctx.strokeStyle = '#2196F3';
    ctx.lineWidth = 2;
    ctx.beginPath();
    
    connectionHistory.forEach((point, index) => {
        const x = padding + (width / (connectionHistory.length - 1)) * index;
        const y = padding + height - (point.connections / maxConnections) * height;
        
        if (index === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
    });
    
    ctx.stroke();
    
    // 绘制数据点
    ctx.fillStyle = '#2196F3';
    connectionHistory.forEach((point, index) => {
        const x = padding + (width / (connectionHistory.length - 1)) * index;
        const y = padding + height - (point.connections / maxConnections) * height;
        
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, Math.PI * 2);
        ctx.fill();
    });
}

// 加载设备列表
function loadDevices() {
    fetch('/api/devices')
        .then(res => res.json())
        .then(devices => {
            const container = document.getElementById('devices-list');
            
            if (devices.length === 0) {
                container.innerHTML = '<p class="loading">暂无连接设备</p>';
                return;
            }
            
            container.innerHTML = devices.map(device => `
                <div class="device-card ${device.online ? 'online' : 'offline'}">
                    <div class="device-header">
                        <div class="device-name">
                            ${device.name || '未知设备'}
                        </div>
                        <div class="device-status ${device.online ? 'online' : 'offline'}">
                            ${device.online ? '在线' : '离线'}
                        </div>
                    </div>
                    <div class="device-info">
                        <div>IP: ${device.ip || 'N/A'}</div>
                        <div>连接时间: ${device.connected_at || 'N/A'}</div>
                        <div>类型: ${device.type || 'Unknown'}</div>
                    </div>
                </div>
            `).join('');
        })
        .catch(err => {
            console.error('加载设备列表失败:', err);
            document.getElementById('devices-list').innerHTML = 
                '<p class="loading">加载失败</p>';
        });
}

// 加载Shadowrocket配置
async function loadShadowrocketConfig() {
    try {
        const response = await fetch('/api/config');
        if (!response.ok) {
            throw new Error(`配置接口返回错误: ${response.status}`);
        }
        const result = await response.json();
        
        if (!result.success) {
            document.getElementById('config-panel').innerHTML = `
                <div class="error-message">
                    <h4>⚠️ 配置加载失败</h4>
                    <p>${result.message || '请先运行部署脚本生成配置'}</p>
                </div>
            `;
            return;
        }
        
        const { vmessLink, qrCode, serverInfo, instructions } = result.data;
        
        // 生成配置面板HTML
        document.getElementById('config-panel').innerHTML = `
            <div class="config-grid">
                <!-- vmess://链接 -->
                <div class="config-card">
                    <h3><span class="config-icon">🔗</span> VMess链接</h3>
                    <div class="copy-container">
                        <input type="text" class="vmess-input" value="${vmessLink}" readonly>
                        <button class="copy-btn" onclick="copyToClipboard('${vmessLink}')">
                            <span class="copy-icon">📋</span> 复制
                        </button>
                    </div>
                    <p class="config-hint">复制此链接到Shadowrocket中导入</p>
                </div>
                
                <!-- 二维码 -->
                <div class="config-card">
                    <h3><span class="config-icon">📱</span> 扫码导入</h3>
                    <div class="qr-container">
                        <img src="${qrCode}" alt="VMess配置二维码" class="qr-code">
                    </div>
                    <p class="config-hint">使用手机相机扫描此二维码</p>
                </div>
                
                <!-- 服务器信息 -->
                <div class="config-card">
                    <h3><span class="config-icon">⚙️</span> 服务器信息</h3>
                    <table class="info-table">
                        <tr><td>地址</td><td><code>${serverInfo.domain}</code></td></tr>
                        <tr><td>端口</td><td><code>${serverInfo.port}</code></td></tr>
                        <tr><td>协议</td><td>${serverInfo.protocol}</td></tr>
                        <tr><td>路径</td><td><code>${serverInfo.ws_path}</code></td></tr>
                        <tr><td>UUID</td><td><code class="uuid">${serverInfo.uuid}</code></td></tr>
                    </table>
                    <p class="config-hint">${instructions.ios}</p>
                </div>
            </div>
        `;
        
    } catch (error) {
        document.getElementById('config-panel').innerHTML = `
            <div class="error-message">
                <h4>❌ 网络错误</h4>
                <p>无法连接到配置服务器: ${error.message}</p>
            </div>
        `;
    }
}

// 复制到剪贴板
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        alert('✅ vmess://链接已复制到剪贴板！');
    }).catch(err => {
        console.error('复制失败:', err);
        alert('❌ 复制失败，请手动复制');
    });
}

// Socket事件监听
socket.on('stats', (stats) => {
    updateStats(stats);
    updateConnectionHistory(stats.connections || 0);
    updateServerInfo();
});

socket.on('connect', () => {
    console.log('已连接到监控服务器');
    loadDevices();
});

socket.on('disconnect', () => {
    console.log('与监控服务器断开连接');
});

// 定期加载设备列表
setInterval(loadDevices, 30000);

// 初始化
loadDevices();
loadShadowrocketConfig();

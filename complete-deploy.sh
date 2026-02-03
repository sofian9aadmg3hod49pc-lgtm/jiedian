#!/bin/bash

# 完整部署脚本 - 在本地执行即可自动完成所有部署

set -e

echo "========================================"
echo "Shadowrocket配置中心 - 自动部署"
echo "========================================"
echo ""

# 配置
SERVER="66.42.124.79"
PASSWORD="8@DqCfQ9)QK)rE9["
LOCAL_DIR="/workspace/monitor-dashboard"
REMOTE_DIR="/root/monitor-dashboard"

# 1. 打包本地文件
echo "步骤 1/7: 打包监控面板文件..."
cd "$LOCAL_DIR"
tar -czf /tmp/monitor.tar.gz .
echo "✅ 打包完成"
ls -lh /tmp/monitor.tar.gz

# 2. 上传到服务器
echo ""
echo "步骤 2/7: 上传文件到服务器..."
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no /tmp/monitor.tar.gz root@$SERVER:/tmp/
echo "✅ 上传完成"

# 3. 备份现有配置
echo ""
echo "步骤 3/7: 备份现有配置..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << 'ENDSSH'
cd /root
if [ -d "monitor-dashboard" ]; then
    BACKUP_DIR="monitor-dashboard-backup-$(date +%Y%m%d_%H%M%S)"
    mv monitor-dashboard "$BACKUP_DIR"
    echo "✅ 已备份到: $BACKUP_DIR"
else
    echo "ℹ️  首次部署，无需备份"
fi
mkdir -p monitor-dashboard
ENDSSH

# 4. 解压新文件
echo ""
echo "步骤 4/7: 解压新文件..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << 'ENDSSH'
cd /root/monitor-dashboard
tar -xzf /tmp/monitor.tar.gz
rm /tmp/monitor.tar.gz
echo "✅ 解压完成"
ENDSSH

# 5. 安装依赖
echo ""
echo "步骤 5/7: 安装 Node.js 依赖..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << 'ENDSSH'
cd /root/monitor-dashboard
npm install --silent
echo "✅ 依赖安装完成"
ENDSSH

# 6. 设置权限和启动服务
echo ""
echo "步骤 6/7: 安装数据收集器并启动服务..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << 'ENDSSH'
# 设置配置文件权限
chmod 644 /tmp/v2ray-info.json 2>/dev/null || echo "警告: V2Ray配置文件不存在"

# 安装数据收集器
echo "安装V2Ray数据收集器..."
cp /root/monitor-dashboard/collector/v2ray-stats-collector.js /usr/local/bin/
chmod +x /usr/local/bin/v2ray-stats-collector.js

# 安装Systemd服务
echo "安装Systemd定时器..."
cp /root/monitor-dashboard/systemd/monitor-collector.service /etc/systemd/system/
cp /root/monitor-dashboard/systemd/monitor-collector.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable monitor-collector.timer
systemctl start monitor-collector.timer

# 应用V2Ray日志配置补丁
echo "应用V2Ray访问日志配置..."
if [ -f "/root/monitor-dashboard/v2ray-patch/apply-access-log-patch.sh" ]; then
    bash /root/monitor-dashboard/v2ray-patch/apply-access-log-patch.sh
else
    echo "警告: V2Ray补丁脚本不存在"
fi

# 停止旧服务
pkill -f "node.*server.js" 2>/dev/null || echo "未发现旧服务"

# 等待端口释放
sleep 2

# 启动新服务
cd /root/monitor-dashboard
nohup node server.js > /var/log/monitor.log 2>&1 &

# 等待服务启动
sleep 3

# 检查服务状态
if ps aux | grep -q "[n]ode.*server.js"; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败"
    tail -20 /var/log/monitor.log
    exit 1
fi

# 检查数据收集定时器
if systemctl is-active --quiet monitor-collector.timer; then
    echo "✅ 数据收集定时器已启动"
else
    echo "⚠️  数据收集定时器未启动"
fi
ENDSSH

# 7. 验证部署
echo ""
echo "步骤 7/7: 验证部署..."
sleep 2

echo ""
echo "检查服务状态..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@$SERVER << 'ENDSSH'
echo "========================================"
echo "进程状态："
ps aux | grep "[n]ode.*server.js"
echo ""
echo "最近日志："
tail -10 /var/log/monitor.log
ENDSSH

echo ""
echo "========================================"
echo "✅ 部署完成！"
echo "========================================"
echo ""
echo "访问地址："
echo "  http://ttjj11233.duckdns.org:3001"
echo ""
echo "登录信息："
echo "  用户名: admin"
echo "  密码: v2raymonitor"
echo ""
echo "新功能："
echo "  在页面底部查看「Shadowrocket 配置」区域"
echo "  - 一键复制 vmess:// 链接"
echo "  - 扫描二维码导入"
echo "  - 查看完整服务器配置"
echo ""
echo "测试方法："
echo "  1. 打开浏览器访问监控面板"
echo "  2. 登录后向下滚动到配置区域"
echo "  3. 点击复制按钮测试复制功能"
echo "  4. 用手机扫描二维码测试扫码功能"
echo ""
echo "如遇问题，执行以下命令查看日志："
echo "  ssh root@66.42.124.79"
echo "  tail -f /var/log/monitor.log"

#!/bin/bash
# =====================================================
# GitHub 备份脚本
# 自动备份V2Ray配置到GitHub
# =====================================================

GITHUB_REPO=${GITHUB_REPO:-"sofian9aadmg3hod49pc-lgtm/jiedian"}
GITHUB_TOKEN=${GITHUB_TOKEN:-""}

# 备份目录
BACKUP_DIR="/tmp/v2ray-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查GitHub Token
check_github_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}[ERROR]${NC} GITHUB_TOKEN环境变量未设置"
        echo "请设置: export GITHUB_TOKEN=your_token_here"
        return 1
    fi
    return 0
}

# 创建备份目录
create_backup_dir() {
    mkdir -p ${BACKUP_DIR}
}

# 备份V2Ray配置
backup_v2ray_config() {
    echo "备份V2Ray配置..."
    
    if [ -f /usr/local/etc/v2ray/config.json ]; then
        cp /usr/local/etc/v2ray/config.json ${BACKUP_DIR}/v2ray-config-${TIMESTAMP}.json
        echo -e "${GREEN}[OK]${NC} V2Ray配置已备份"
    fi
    
    if [ -f /tmp/v2ray-info.json ]; then
        cp /tmp/v2ray-info.json ${BACKUP_DIR}/v2ray-info-${TIMESTAMP}.json
        echo -e "${GREEN}[OK]${NC} V2Ray信息已备份"
    fi
}

# 备份SSL证书信息
backup_ssl_info() {
    echo "备份SSL证书信息..."
    
    if [ -f /etc/letsencrypt/live/ttjj11233.duckdns.org/fullchain.pem ]; then
        cert_info=$(openssl x509 -in /etc/letsencrypt/live/ttjj11233.duckdns.org/fullchain.pem -noout -text)
        echo "$cert_info" > ${BACKUP_DIR}/ssl-cert-info-${TIMESTAMP}.txt
        echo -e "${GREEN}[OK]${NC} SSL证书信息已备份"
    fi
}

# 备份监控数据
backup_monitor_data() {
    echo "备份监控数据..."
    
    if [ -d /tmp/monitor/data ]; then
        tar -czf ${BACKUP_DIR}/monitor-data-${TIMESTAMP}.tar.gz -C /tmp/monitor data 2>/dev/null
        echo -e "${GREEN}[OK]${NC} 监控数据已备份"
    fi
}

# 创建备份日志
create_backup_log() {
    cat > ${BACKUP_DIR}/backup-log-${TIMESTAMP}.txt <<EOF
========================================
V2Ray 备份日志
========================================
备份时间: $(date)
备份类型: 自动备份

备份文件列表:
- v2ray-config-${TIMESTAMP}.json
- v2ray-info-${TIMESTAMP}.json
- ssl-cert-info-${TIMESTAMP}.txt
- monitor-data-${TIMESTAMP}.tar.gz (如果有)

服务器信息:
$(uname -a)
EOF
    echo -e "${GREEN}[OK]${NC} 备份日志已创建"
}

# 上传到GitHub
upload_to_github() {
    echo "上传备份到GitHub..."
    
    # 创建临时提交
    cd ${BACKUP_DIR}
    git init
    git add .
    git commit -m "Backup ${TIMESTAMP}"
    
    # 推送到GitHub
    git remote add origin https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git
    git push -u origin main || git push -u origin master
    
    echo -e "${GREEN}[OK]${NC} 备份已上传到GitHub"
}

# 清理旧备份
cleanup_old_backups() {
    echo "清理旧备份（保留最近7天）..."
    
    find ${BACKUP_DIR} -name "*.json" -mtime +7 -delete
    find ${BACKUP_DIR} -name "*.txt" -mtime +7 -delete
    find ${BACKUP_DIR} -name "*.tar.gz" -mtime +7 -delete
    
    echo -e "${GREEN}[OK]${NC} 旧备份已清理"
}

# 主函数
main() {
    if check_github_token; then
        create_backup_dir
        backup_v2ray_config
        backup_ssl_info
        backup_monitor_data
        create_backup_log
        upload_to_github
        cleanup_old_backups
        
        echo ""
        echo -e "${GREEN}[SUCCESS]${NC} 备份完成！"
    else
        exit 1
    fi
}

main

#!/bin/bash

###############################################################################
# 自动同步脚本 - Jiedian V2Ray 项目
# 功能: 自动检测本地更改并推送到 GitHub
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
PROJECT_DIR="/workspace/jiedian"
LOG_FILE="$PROJECT_DIR/.git/sync.log"
GITHUB_REPO="https://github.com/sofian9aadmg3hod49pc-lgtm/jiedian"

# 函数: 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $message"
}

# 函数: 写入日志
log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# 函数: 检查是否有更改
check_changes() {
    cd "$PROJECT_DIR"
    local changes
    changes=$(git status --porcelain | wc -l)
    echo $changes
}

# 函数: 检查远程状态
check_remote_status() {
    cd "$PROJECT_DIR"
    local local_sha
    local remote_sha
    local branch="main"

    # 获取本地 SHA
    local_sha=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

    # 获取远程 SHA
    remote_sha=$(git ls-remote origin "$branch" 2>/dev/null | awk '{print $1}' || echo "unknown")

    echo "$local_sha|$remote_sha"
}

# 函数: 添加所有更改
add_changes() {
    cd "$PROJECT_DIR"
    print_message "$BLUE" "检测到本地更改，正在添加..."
    git add -A
    log_message "已添加所有更改"
    print_message "$GREEN" "更改已添加"
}

# 函数: 提交更改
commit_changes() {
    cd "$PROJECT_DIR"
    local commit_message="Auto-sync: Update $(date '+%Y-%m-%d %H:%M:%S')"

    print_message "$BLUE" "正在提交更改..."
    git commit -m "$commit_message"
    log_message "已提交: $commit_message"
    print_message "$GREEN" "更改已提交"
}

# 函数: 推送更改
push_changes() {
    cd "$PROJECT_DIR"
    local force_flag=""

    # 检查是否需要强制推送
    local status
    status=$(check_remote_status)
    local local_sha=$(echo "$status" | cut -d'|' -f1)
    local remote_sha=$(echo "$status" | cut -d'|' -f2)

    if [ "$local_sha" != "$remote_sha" ]; then
        print_message "$YELLOW" "检测到历史分叉，将使用强制推送"
        force_flag="--force"
        log_message "检测到历史分叉，本地: $local_sha, 远程: $remote_sha"
    fi

    print_message "$BLUE" "正在推送到 GitHub..."
    if git push origin main $force_flag; then
        print_message "$GREEN" "✓ 推送成功！"
        log_message "推送成功 ($force_flag)"

        # 显示仓库链接
        print_message "$BLUE" "仓库地址: $GITHUB_REPO"
        print_message "$BLUE" "访问: https://github.com/sofian9aadmg3hod49pc-lgtm/jiedian"
        return 0
    else
        print_message "$RED" "✗ 推送失败！"
        log_message "推送失败"
        return 1
    fi
}

# 函数: 显示当前状态
show_status() {
    cd "$PROJECT_DIR"

    print_message "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "$BLUE" "       Jiedian 项目 - 自动同步状态"
    print_message "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 分支信息
    print_message "$BLUE" "当前分支:"
    git branch --show-current 2>/dev/null || echo "N/A"

    # 本地提交
    print_message "$BLUE" "\n最近提交:"
    git log --oneline -5 2>/dev/null || echo "N/A"

    # 更改状态
    print_message "$BLUE" "\n文件状态:"
    local changes
    changes=$(git status --short 2>/dev/null || echo "N/A")
    if [ -n "$changes" ]; then
        echo "$changes"
    else
        print_message "$GREEN" "工作区干净，无更改"
    fi

    # 远程状态
    print_message "$BLUE" "\n远程状态:"
    local status
    status=$(check_remote_status)
    local local_sha=$(echo "$status" | cut -d'|' -f1)
    local remote_sha=$(echo "$status" | cut -d'|' -f2)

    if [ "$local_sha" = "$remote_sha" ]; then
        print_message "$GREEN" "✓ 本地和远程已同步"
    else
        print_message "$YELLOW" "⚠ 本地和远程不同步"
        print_message "$YELLOW" "  本地 SHA: ${local_sha:0:8}"
        print_message "$YELLOW" "  远程 SHA: ${remote_sha:0:8}"
    fi

    print_message "$BLUE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 函数: 完整同步流程
full_sync() {
    print_message "$BLUE" "开始同步流程..."

    show_status

    # 检查是否有更改
    local changes
    changes=$(check_changes)

    if [ "$changes" -eq 0 ]; then
        print_message "$YELLOW" "没有检测到本地更改"
        log_message "无更改需要同步"

        # 检查是否需要推送
        local status
        status=$(check_remote_status)
        local local_sha=$(echo "$status" | cut -d'|' -f1)
        local remote_sha=$(echo "$status" | cut -d'|' -f2)

        if [ "$local_sha" != "$remote_sha" ]; then
            print_message "$YELLOW" "本地和远程不同步，尝试推送..."
            push_changes
        else
            print_message "$GREEN" "✓ 已是最新状态，无需操作"
        fi
    else
        print_message "$YELLOW" "检测到 $changes 个更改"

        # 添加更改
        add_changes

        # 提交更改
        commit_changes

        # 推送更改
        if push_changes; then
            print_message "$GREEN" "✓ 同步完成！"
            log_message "同步流程完成"
        else
            print_message "$RED" "✗ 同步失败"
            return 1
        fi
    fi
}

# 主函数
main() {
    case "${1:-sync}" in
        status)
            show_status
            ;;
        sync)
            full_sync
            ;;
        push)
            push_changes
            ;;
        force)
            cd "$PROJECT_DIR"
            print_message "$YELLOW" "强制推送到远程..."
            git push --force origin main
            log_message "强制推送完成"
            print_message "$GREEN" "✓ 强制推送完成"
            ;;
        *)
            echo "用法: $0 {status|sync|push|force}"
            echo ""
            echo "命令:"
            echo "  status  - 显示当前状态"
            echo "  sync    - 完整同步流程（添加、提交、推送）"
            echo "  push    - 仅推送已有提交"
            echo "  force   - 强制推送到远程"
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"

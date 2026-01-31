#!/bin/bash

echo "=================================="
echo "GitHub 连接测试"
echo "=================================="
echo ""

# 1. 检查 Git 配置
echo "1. Git 配置:"
echo "-----------"
cd /workspace/jiedian
echo "用户名: $(git config user.name)"
echo "邮箱: $(git config user.email)"
echo ""

# 2. 检查远程仓库
echo "2. 远程仓库:"
echo "-----------"
git remote -v
echo ""

# 3. 检查本地提交
echo "3. 本地提交:"
echo "-----------"
git log --oneline -5 2>&1 || echo "无法获取提交历史"
echo ""

# 4. 检查本地 SHA
echo "4. 本地 SHA:"
echo "-----------"
git rev-parse HEAD 2>&1 || echo "无法获取本地 SHA"
echo ""

# 5. 检查远程 SHA
echo "5. 远程 SHA:"
echo "-----------"
git ls-remote origin main 2>&1 || echo "无法获取远程 SHA"
echo ""

# 6. 测试 GitHub 连通性
echo "6. GitHub 连通性:"
echo "---------------"
if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
    echo "✓ 可以连接到 GitHub"
else
    echo "✗ 无法连接到 GitHub"
fi
echo ""

# 7. 检查认证方式
echo "7. 认证配置:"
echo "-----------"
echo "URL: $(git remote get-url origin)"
if [[ $(git remote get-url origin) == git@* ]]; then
    echo "方式: SSH"
    echo "测试 SSH: $(ssh -o ConnectTimeout=5 -T git@github.com 2>&1 | head -1)"
else
    echo "方式: HTTPS"
    echo "Credential helper: $(git config credential.helper)"
fi
echo ""

echo "=================================="
echo "测试完成"
echo "=================================="

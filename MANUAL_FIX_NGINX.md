# Nginx 反向代理修复 - 手动执行指南

## 📋 修复目标
使监控面板可通过以下地址访问:
- `http://216.128.151.224/`
- `http://216.128.151.224/monitor/`

## 🔧 手动修复步骤

### 方法一: 使用修复脚本(推荐)

#### 1. 上传脚本到服务器
```bash
scp fix-nginx-monitor.sh root@216.128.151.224:/tmp/
```

#### 2. SSH 登录服务器
```bash
ssh root@216.128.151.224
```

#### 3. 执行修复脚本
```bash
sudo bash /tmp/fix-nginx-monitor.sh
```

---

### 方法二: 手动执行命令

#### 步骤 1: SSH 登录服务器
```bash
ssh root@216.128.151.224
```

#### 步骤 2: 备份当前配置
```bash
sudo mkdir -p /etc/nginx/backup
sudo cp /etc/nginx/sites-available/default /etc/nginx/backup/nginx_config_fixed_$(date +%Y%m%d_%H%M%S).conf
```

#### 步骤 3: 创建新的简化配置
```bash
sudo tee /etc/nginx/sites-available/monitor << 'EOF'
server {
    listen 80;
    server_name _;
    
    client_max_body_size 10M;
    
    # 监控面板主路由
    location / {
        proxy_pass http://127.0.0.1:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }
    
    # API 路由
    location /api/ {
        proxy_pass http://127.0.0.1:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 兼容 /monitor/ 路径
    location ^~ /monitor/ {
        proxy_pass http://127.0.0.1:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

#### 步骤 4: 启用新配置
```bash
sudo ln -sf /etc/nginx/sites-available/monitor /etc/nginx/sites-enabled/default
```

#### 步骤 5: 测试配置
```bash
sudo nginx -t
```

#### 步骤 6: 重启 Nginx
```bash
sudo systemctl restart nginx
```

---

### 方法三: 快速修复(最小改动)

如果只想让反向代理立即工作:

```bash
# SSH 登录
ssh root@216.128.151.224

# 直接修改默认配置,将所有请求代理到监控服务
sudo sed -i 's|proxy_pass http://localhost:3000;|proxy_pass http://127.0.0.1:3001;|' /etc/nginx/sites-available/default

# 测试并重启
sudo nginx -t && sudo systemctl restart nginx
```

---

## ✅ 验证修复

### 1. 检查服务状态
```bash
# Nginx 状态
systemctl status nginx

# 端口监听
ss -tuln | grep -E ':80|:3001'
```

### 2. 测试本地访问
```bash
# 在服务器上测试
curl -I http://localhost
curl -I http://localhost/monitor/
```

### 3. 测试外部访问
在浏览器中访问:
- `http://216.128.151.224/`
- `http://216.128.151.224/monitor/`

预期结果: 应该看到监控面板登录界面

---

## 🔙 恢复备份(如果需要)

如果修复后出现问题:

```bash
# 查看备份文件
ls -lh /etc/nginx/backup/

# 恢复最近的备份(替换时间戳)
sudo cp /etc/nginx/backup/nginx_config_fixed_20260203_HHMMSS.conf /etc/nginx/sites-available/default
sudo systemctl restart nginx
```

---

## 📊 当前配置说明

修复前的问题:
- Nginx 配置中 `location /` 代理到不存在的 `localhost:3000`(聊天室服务)
- 导致访问 `http://216.128.151.224/monitor/` 时无法正确路由

修复后的配置:
- 所有路径(`/`, `/api/`, `/monitor/`)统一代理到 `127.0.0.1:3001`
- 监控服务运行正常(已确认 `http://216.128.151.224:3001` 可访问)
- 通过反向代理实现80端口统一访问

---

## 💡 常见问题

### Q: SSH 连接失败怎么办?
A: 请检查:
1. 服务器IP是否正确: `216.128.151.224`
2. SSH密钥是否配置: `ls ~/.ssh/id_rsa*`
3. 使用密码登录: `ssh root@216.128.151.224` (输入密码)

### Q: Nginx 重启失败怎么办?
A: 运行以下命令查看错误:
```bash
sudo nginx -t
sudo journalctl -u nginx -n 20
```

### Q: 修复后仍无法访问?
A: 检查防火墙:
```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw reload
```

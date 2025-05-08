#!/bin/bash

set -e

echo "📦 Updating system..."
apt update && apt upgrade -y

echo "🧹 Removing old Node.js..."
apt remove --purge -y nodejs npm || true
rm -rf /usr/local/lib/node_modules /usr/local/bin/node /usr/local/bin/npm

echo "📥 Installing NVM and Node.js 20..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install 20
nvm use 20

NODE_PATH=$(which node)
NPM_PATH=$(which npm)

echo "✅ Node: $(node -v), NPM: $(npm -v)"

echo "📁 Cloning iPWGD..."
rm -rf /etc/ipwgd
mkdir -p /etc/ipwgd

# استخراج frontend نهایی
echo "⬇️ Extracting frontend..."
curl -L -o /tmp/ipwgd-frontend-final.zip https://sandbox.openai.com/mnt/data/ipwgd-frontend-final.zip
unzip /tmp/ipwgd-frontend-final.zip -d /etc/ipwgd/frontend

# استخراج backend نهایی
echo "⬇️ Extracting backend..."
curl -L -o /tmp/ipwgd-backend-project.zip https://sandbox.openai.com/mnt/data/ipwgd-backend-project.zip
unzip /tmp/ipwgd-backend-project.zip -d /etc/ipwgd/backend

# نصب وابستگی backend
echo "🐍 Installing backend..."
cd /etc/ipwgd/backend
pip3 install -r requirements.txt

cat >/etc/systemd/system/ipwgd-backend.service <<EOF
[Unit]
Description=iPWGD Backend (Flask)
After=network.target

[Service]
WorkingDirectory=/etc/ipwgd/backend
ExecStart=/usr/bin/python3 app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# نصب و build frontend
echo "⚛️ Installing frontend..."
cd /etc/ipwgd/frontend
source "$NVM_DIR/nvm.sh"
nvm use 20
$NPM_PATH install
$NPM_PATH run build

cat >/etc/systemd/system/ipwgd-frontend.service <<EOF
[Unit]
Description=iPWGD Frontend (Next.js)
After=network.target

[Service]
WorkingDirectory=/etc/ipwgd/frontend
ExecStart=$NPM_PATH start
Restart=always
User=root
Environment=PORT=8000
Environment=NEXT_PUBLIC_API_URL=http://localhost:13640

[Install]
WantedBy=multi-user.target
EOF

# راه‌اندازی سرویس‌ها
echo "🚀 Enabling services..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now ipwgd-backend
systemctl enable --now ipwgd-frontend

echo "✅ iPWGD is ready at http://<your-server-ip>:8000"

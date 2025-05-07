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

echo "📁 Cloning iPWGD to /etc/ipwgd..."
rm -rf /etc/ipwgd
git clone https://github.com/iPmartNetwork/iPWGD /etc/ipwgd

echo "🐍 Installing backend..."
cd /etc/ipwgd/backend
cat > requirements.txt <<EOF
Flask==2.3.2
flask-cors==4.0.0
requests==2.31.0
EOF
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

echo "⚛️ Installing frontend..."
cd /etc/ipwgd/frontend
rm -rf node_modules package-lock.json
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
Environment=NEXT_PUBLIC_API_URL=http://localhost:8000
Environment=PORT=8000

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Enabling services..."
systemctl daemon-reload
systemctl enable --now ipwgd-backend
systemctl enable --now ipwgd-frontend

echo "✅ iPWGD is ready at http://<your-server-ip>:8000"

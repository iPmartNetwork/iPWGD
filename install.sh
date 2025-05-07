#!/bin/bash

set -e

echo "📦 Updating system..."
apt update && apt upgrade -y

echo "🧹 Removing old Node.js..."
apt remove --purge -y nodejs npm libnode-dev libnode72 libnode-dev-common || true
rm -rf /usr/include/node /usr/lib/node_modules /etc/node /usr/bin/node /usr/bin/npm

echo "📥 Installing NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

echo "⬇️ Installing Node.js LTS version with NVM..."
nvm install --lts
nvm use --lts

NODE_BIN_PATH=$(which node)
NPM_BIN_PATH=$(which npm)

echo "✅ Node: $NODE_BIN_PATH ($(node -v)), NPM: $NPM_BIN_PATH ($(npm -v))"

echo "📁 Cloning iPWGD project to /root/ipwgd..."
rm -rf /root/ipwgd
git clone https://github.com/iPmartNetwork/iPWGD /root/ipwgd

echo "🐍 Installing backend dependencies..."
cd /root/ipwgd/backend
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
WorkingDirectory=/root/ipwgd/backend
ExecStart=/usr/bin/python3 app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "⚛️ Installing frontend (Next.js)..."
cd /root/ipwgd/frontend
rm -rf node_modules package-lock.json
npm install

# ✅ Fix import path error for globals.css
sed -i 's|style../styles|styles|g' ./app/layout.tsx
sed -i 's|./globals.css|../styles/globals.css|g' ./app/layout.tsx

npm run build

cat >/etc/systemd/system/ipwgd-frontend.service <<EOF
[Unit]
Description=iPWGD Frontend (Next.js)
After=network.target

[Service]
WorkingDirectory=/root/ipwgd/frontend
ExecStart=$NPM_BIN_PATH start
Restart=always
User=root
Environment=NEXT_PUBLIC_API_URL=http://localhost:13640

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Enabling and starting services..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now ipwgd-backend
systemctl enable --now ipwgd-frontend

echo "✅ iPWGD successfully installed!"
echo "🔗 Access panel at: http://<your-server-ip>:8000"

#!/bin/bash

set -e

echo "📦 Updating system..."
apt update && apt upgrade -y

echo "🧹 Removing old Node.js versions..."
apt remove --purge -y nodejs libnode-dev libnode72 libnode-dev-common || true
rm -rf /usr/include/node /usr/lib/node_modules /etc/node /var/cache/apt/archives/nodejs_*

echo "📥 Installing Node.js v20 (from NodeSource)..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "🧠 Node.js version: $(node -v)"
echo "🧠 NPM version: $(npm -v)"

echo "📦 Installing other dependencies..."
apt install -y git python3 python3-pip curl

echo "📁 Cloning iPWGD to /etc/ipwgd..."
rm -rf /etc/ipwgd
git clone https://github.com/iPmartNetwork/iPWGD /etc/ipwgd

echo "🐍 Setting up backend (Flask)..."
cd /etc/ipwgd/backend

# Create backend requirements if missing
cat > requirements.txt <<EOF
Flask==2.3.2
flask-cors==4.0.0
requests==2.31.0
EOF

pip3 install -r requirements.txt

# systemd backend service
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

echo "⚛️ Setting up frontend (Next.js)..."
cd /etc/ipwgd/frontend
rm -rf node_modules package-lock.json
npm install
npm run build

# systemd frontend service
cat >/etc/systemd/system/ipwgd-frontend.service <<EOF
[Unit]
Description=iPWGD Frontend (Next.js)
After=network.target

[Service]
WorkingDirectory=/etc/ipwgd/frontend
ExecStart=/usr/bin/npm start
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
echo "➡️ Access the admin panel: http://<your-server-ip>:8000"

#!/bin/bash

set -e

echo "📦 Updating system..."
apt update && apt upgrade -y

echo "🧹 Removing old Node.js..."
apt remove --purge -y nodejs npm libnode-dev libnode72 libnode-dev-common || true
rm -rf /usr/include/node /usr/lib/node_modules /etc/node /usr/bin/node /usr/bin/npm

echo "📥 Installing Node.js (via n)..."
apt install -y curl python3 python3-pip git build-essential

curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -
export PATH="/usr/local/bin:$PATH"
n lts

echo "✅ Node: $(node -v), NPM: $(npm -v)"

echo "📁 Cloning iPWGD project to /etc/ipwgd..."
rm -rf /etc/ipwgd
git clone https://github.com/iPmartNetwork/iPWGD /etc/ipwgd

echo "🐍 Installing backend dependencies..."
cd /etc/ipwgd/backend
cat > requirements.txt <<EOF
Flask==2.3.2
flask-cors==4.0.0
requests==2.31.0
EOF
pip3 install --no-cache-dir -r requirements.txt  # Added --no-cache-dir for efficiency

cat >/etc/systemd/system/ipwgd-backend.service <<EOF
[Unit]
Description=iPWGD Backend (Flask)
After=network.target

[Service]
WorkingDirectory=/etc/ipwgd/backend
ExecStart=/usr/bin/python3 app.py
Restart=always
User=root
Environment=PYTHONUNBUFFERED=1  # Ensures logs are not buffered

[Install]
WantedBy=multi-user.target
EOF

echo "⚛️ Installing frontend (Next.js)..."
cd /etc/ipwgd/frontend
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps  # Added flag to handle dependency conflicts

# ✅ Fix import path error for globals.css
sed -i 's|style../styles|styles|g' ./app/layout.tsx || true
sed -i 's|./globals.css|../styles/globals.css|g' ./app/layout.tsx || true

npm run build

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
echo "🔗 Access panel at: http://<your-server-ip>:8000"

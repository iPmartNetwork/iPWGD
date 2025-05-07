#!/bin/bash

set -e

echo "📦 Updating system..."
apt update && apt upgrade -y

echo "📦 Installing dependencies..."
apt install -y git python3 python3-pip nodejs npm curl

echo "📁 Cloning iPWGD to /etc/ipwgd..."
rm -rf /etc/ipwgd
git clone https://github.com/iPmartNetwork/iPWGD /etc/ipwgd

echo "🐍 Setting up backend (Flask)..."
cd /etc/ipwgd/backend

# ✅ Create requirements.txt BEFORE installation
echo "Creating backend requirements.txt..."
cat > requirements.txt <<EOF
Flask==2.3.2
flask-cors==4.0.0
requests==2.31.0
EOF

# ✅ Install Python dependencies
pip3 install -r requirements.txt

# ✅ Create systemd service for backend
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
npm install
npm run build

# ✅ Create systemd service for frontend
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

echo "✅ iPWGD is fully installed and running!"
echo "🔗 Access the dashboard at: http://<your-server-ip>:8000"

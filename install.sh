#!/bin/bash

set -e

echo "📦 Updating system..."
apt update && apt upgrade -y

echo "🧹 Removing old Node.js and npm..."
apt remove --purge -y nodejs npm libnode-dev libnode72 libnode-dev-common || true
rm -rf /usr/include/node /usr/lib/node_modules /etc/node /usr/bin/node /usr/bin/npm

echo "📥 Installing Node.js & npm via 'n' (node version manager)..."
apt install -y curl python3 python3-pip git build-essential

# نصب n و node
curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -
export PATH="/usr/local/bin:$PATH"
n stable

echo "🧠 Node.js version: $(node -v)"
echo "🧠 npm version: $(npm -v)"

echo "📁 Cloning iPWGD to /etc/ipwgd..."
rm -rf /etc/ipwgd
git clone https://github.com/iPmartNetwork/iPWGD /etc/ipwgd

echo "🐍 Setting up backend (Flask)..."
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

echo "⚛️ Setting up frontend (Next.js)..."
cd /etc/ipwgd/frontend
rm -rf node_modules package-lock.json
npm install

# مسیر درست CSS
sed -i 's|./globals.css|../styles/globals.css|g' ./app/layout.tsx

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

echo "✅ iPWGD is fully installed and running!"
echo "🔗 Access it at: http://<your-server-ip>:8000"

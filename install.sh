#!/bin/bash
set -e

echo "📦 Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y curl git python3 python3-pip build-essential

echo "📥 Installing NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install --lts
nvm use --lts

echo "🔧 Cloning iPWGD to /etc/ipwgd..."
rm -rf /etc/ipwgd
git clone https://github.com/iPmartNetwork/iPWGD /etc/ipwgd

echo "🐍 Installing Python backend dependencies..."
cd /etc/ipwgd/backend
cat > requirements.txt <<EOF
Flask==2.3.2
flask-cors==4.0.0
requests==2.31.0
EOF
pip3 install -r requirements.txt

echo "⚙️ Creating backend service..."
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

echo "⚛️ Installing frontend dependencies and fixing layout..."
cd /etc/ipwgd/frontend
rm -rf node_modules .next package-lock.json
npm install

cat > app/layout.tsx <<EOF
import '../styles/globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'iPWGD Dashboard',
  description: 'WireGuard Dashboard for iPmart Network',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head />
      <body>{children}</body>
    </html>
  );
}
EOF

mkdir -p styles
cat > styles/globals.css <<EOF
html, body {
  margin: 0;
  padding: 0;
  font-family: Arial, sans-serif;
  background-color: #0f172a;
  color: #f1f5f9;
}
a {
  color: #38bdf8;
  text-decoration: none;
}
* {
  box-sizing: border-box;
}
EOF

cat > app/page.tsx <<EOF
export default function Home() {
  return (
    <div style={{ padding: "2rem" }}>
      <h1>Welcome to iPWGD</h1>
      <p>This is the home page of your WireGuard Dashboard.</p>
    </div>
  );
}
EOF

echo "🧱 Building frontend..."
npm run build

echo "⚙️ Creating frontend service..."
NPM_BIN_PATH=$(which npm)
cat >/etc/systemd/system/ipwgd-frontend.service <<EOF
[Unit]
Description=iPWGD Frontend (Next.js)
After=network.target

[Service]
WorkingDirectory=/etc/ipwgd/frontend
ExecStart=$NPM_BIN_PATH start
Restart=always
User=root
Environment=NEXT_PUBLIC_API_URL=http://localhost:8000

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Enabling and starting services..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now ipwgd-backend
systemctl enable --now ipwgd-frontend

echo "✅ Installation complete. Access your panel at http://<your-server-ip>:8000"

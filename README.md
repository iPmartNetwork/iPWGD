# iPWGD - WireGuard Dashboard

A modern admin dashboard for managing WireGuard peers, limits, and system configuration via a sleek web interface. Built with **Next.js** (frontend) and **Flask** (backend), this project is ideal for VPS owners and VPN providers.

---

## 🚀 Features

- Admin login panel (secured by localStorage-based role)
- Add / Edit / Delete WireGuard peers
- Peer limits by traffic and expiration
- Peer status indicator (online/offline)
- Dark / Light theme toggle
- Filter peers by type: All / Limited / Expired
- Default peer settings with persistence
- Admin-only restrictions for all config operations
- Systemd-based backend/frontend services
- Telegram backup integration (optional)

---

## 📦 Installation

```bash
git clone https://github.com/iPmartNetwork/iPWGD.git
cd iPWGD
bash install.sh
```

The script will:

- Update system & install Node.js + Python dependencies
- Clone the repo into `/etc/ipwgd`
- Install backend Flask server
- Install frontend Next.js dashboard
- Setup systemd services for auto-start

---

## 🌐 Access

Once installed, visit:

```
http://your-server-ip:8000
```

Default credentials are not enforced — use browser localStorage:

```js
localStorage.setItem("auth", "true");
localStorage.setItem("role", "admin");
```

---

## 🛡 Security

- Only `admin` role can change settings or peers.
- Peer changes persist to real WireGuard config (if integrated).
- No external authentication yet — recommend placing behind reverse proxy auth.

---

## 📁 Project Structure

```
iPWGD/
├── backend/     # Flask API
├── frontend/    # Next.js UI
├── install.sh   # Automated installer
└── README.md
```

---

## 📬 Telegram Integration

Coming soon: automatic peer backup to Telegram bot.

---

## 🧑‍💻 Contributing

Feel free to fork, star, or submit pull requests!

---

## 📄 License

MIT © 2025 iPmart Network

from flask import Flask, jsonify
import subprocess
import re

app = Flask(__name__)

@app.route("/api/peers")
def list_peers():
    try:
        with open("/etc/wireguard/wg0.conf") as f:
            conf = f.read()

        peer_blocks = conf.strip().split("[Peer]")
        peers = []

        for block in peer_blocks[1:]:
            name_match = re.search(r"#\s*Name\s*:\s*(.+)", block)
            ip_match = re.search(r"AllowedIPs\s*=\s*(.+)", block)
            pubkey_match = re.search(r"PublicKey\s*=\s*(.+)", block)

            name = name_match.group(1).strip() if name_match else "Unknown"
            ip = ip_match.group(1).strip() if ip_match else "-"
            pubkey = pubkey_match.group(1).strip() if pubkey_match else ""

            peers.append({
                "name": name,
                "ip": ip,
                "pubkey": pubkey,
                "limit": "",
                "expires": ""
            })

        wg_output = subprocess.check_output("wg show all dump", shell=True).decode()
        wg_lines = wg_output.strip().split("\n")[1:]
        wg_status = {}

        for line in wg_lines:
            parts = line.strip().split("\t")
            if len(parts) >= 8:
                key = parts[0]
                handshake = int(parts[5])
                rx = int(parts[6]) // 1024
                tx = int(parts[7]) // 1024
                wg_status[key] = {
                    "status": "online" if handshake > 0 else "offline",
                    "latest_handshake": str(handshake),
                    "transfer_rx": f"{rx} KB",
                    "transfer_tx": f"{tx} KB"
                }

        for peer in peers:
            extra = wg_status.get(peer["pubkey"], {})
            peer.update(extra)

        return jsonify(peers)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/status")
def status():
    try:
        uptime = subprocess.check_output("uptime -p", shell=True).decode().strip()
        cpu = float(subprocess.check_output("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'", shell=True).decode().strip())
        mem_out = subprocess.check_output("free -m", shell=True).decode()
        total, used = map(int, re.findall(r"Mem:\s+(\d+)\s+(\d+)", mem_out)[0])
        ram = round(used / total * 100, 2)
        tunnels = len([l for l in open("/etc/wireguard/wg0.conf") if "[Peer]" in l])
        return jsonify({ "uptime": uptime, "cpu": cpu, "ram": ram, "tunnels": tunnels })
    except Exception as e:
        return jsonify({"error": str(e)}), 500
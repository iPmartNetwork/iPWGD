
from flask import Blueprint, request, jsonify
import json, os
import qrcode
import base64
from io import BytesIO

peers_bp = Blueprint("peers", __name__)
PEERS_FILE = "peers.json"
SETTINGS_FILE = "dashboard_settings.json"

def load_settings():
    if os.path.exists(SETTINGS_FILE):
        with open(SETTINGS_FILE, "r") as f:
            return json.load(f)
    return {}

def load_peers():
    if not os.path.exists(PEERS_FILE):
        return []
    with open(PEERS_FILE, "r") as f:
        return json.load(f)

def save_peers(data):
    with open(PEERS_FILE, "w") as f:
        json.dump(data, f)

@peers_bp.route("/api/peers", methods=["GET"])
def list_peers():
    return jsonify(load_peers())

@peers_bp.route("/api/peers", methods=["POST"])
def add_peer():
    data = request.json
    settings = load_settings()
    peers = load_peers()

    peer = {
        "name": data["name"],
        "limit_data_gb": data.get("limit_data") or settings.get("peer_limit_gb", ""),
        "limit_time_days": data.get("limit_time", ""),
        "dns": settings.get("peer_dns", "8.8.8.8,1.1.1.1"),
        "allowed_ips": settings.get("peer_allowed_ips", "0.0.0.0/0"),
        "mtu": settings.get("peer_mtu", "1280"),
        "keepalive": settings.get("peer_keepalive", "25"),
        "remote_endpoint": settings.get("remote_endpoint", "127.0.0.1")
    }

    peers.append(peer)
    save_peers(peers)
    return jsonify({"status": "added"})

@peers_bp.route("/api/peers", methods=["DELETE"])
def delete_peer():
    name = request.json.get("name")
    peers = [p for p in load_peers() if p["name"] != name]
    save_peers(peers)
    return jsonify({"status": "deleted"})

@peers_bp.route("/api/peers/qr/<name>", methods=["GET"])
def get_qr(name):
    peers = load_peers()
    peer = next((p for p in peers if p["name"] == name), None)
    if not peer:
        return jsonify({"error": "not found"}), 404
    config = (
        f"[Peer]\n"
        f"Name = {peer['name']}\n"
        f"DNS = {peer['dns']}\n"
        f"AllowedIPs = {peer['allowed_ips']}\n"
        f"MTU = {peer['mtu']}\n"
        f"Keepalive = {peer['keepalive']}\n"
        f"Endpoint = {peer['remote_endpoint']}"
    )
    img = qrcode.make(config)
    buf = BytesIO()
    img.save(buf, format='PNG')
    qr_b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
    return jsonify({"qr": qr_b64})

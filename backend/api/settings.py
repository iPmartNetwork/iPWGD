
from flask import Blueprint, request, jsonify
import json
import os

settings_bp = Blueprint("settings", __name__)
SETTINGS_FILE = "dashboard_settings.json"

def load_settings():
    if not os.path.exists(SETTINGS_FILE):
        return {
            "ip_address": "0.0.0.0",
            "listen_port": "13640",
            "theme": "dark"
        }
    with open(SETTINGS_FILE) as f:
        return json.load(f)

def save_settings(settings):
    with open(SETTINGS_FILE, "w") as f:
        json.dump(settings, f)

@settings_bp.route("/api/settings", methods=["GET"])
def get_settings():
    return jsonify(load_settings())

@settings_bp.route("/api/settings", methods=["POST"])
def update_settings():
    data = request.json
    save_settings(data)
    return jsonify({"status": "success"})

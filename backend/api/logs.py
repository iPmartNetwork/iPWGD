
from flask import Blueprint, jsonify, request
import json
import os
from datetime import datetime

logs_bp = Blueprint("logs", __name__)
LOG_FILE = "logs.json"

def append_log(message):
    logs = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            logs = json.load(f)
    logs.append({
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "message": message
    })
    with open(LOG_FILE, "w") as f:
        json.dump(logs[-100:], f)  # keep last 100 logs

@logs_bp.route("/api/logs", methods=["GET"])
def get_logs():
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE) as f:
            return jsonify(json.load(f))
    return jsonify([])

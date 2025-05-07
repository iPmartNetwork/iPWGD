
from flask import Blueprint, request, jsonify
import json
import os

admin_bp = Blueprint("admin", __name__)
PASSWORD_FILE = "admin.json"

def load_password():
    if not os.path.exists(PASSWORD_FILE):
        return "admin123"
    with open(PASSWORD_FILE) as f:
        return json.load(f).get("password", "admin123")

def save_password(new_password):
    with open(PASSWORD_FILE, "w") as f:
        json.dump({"password": new_password}, f)

@admin_bp.route("/api/admin-password", methods=["GET"])
def get_password():
    return jsonify({"password": load_password()})

@admin_bp.route("/api/admin-password", methods=["POST"])
def update_password():
    data = request.json
    if "password" in data:
        save_password(data["password"])
        return jsonify({"status": "success"}), 200
    return jsonify({"error": "Missing password"}), 400

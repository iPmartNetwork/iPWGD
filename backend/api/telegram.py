
from flask import Blueprint, request, jsonify
import requests
import os

telegram_bp = Blueprint("telegram", __name__)

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "your_bot_token_here")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "your_chat_id_here")

@telegram_bp.route("/api/telegram", methods=["POST"])
def send_message():
    data = request.get_json()
    msg = data.get("message", "")
    if not msg:
        return jsonify({"error": "Empty message"}), 400
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    resp = requests.post(url, json={"chat_id": CHAT_ID, "text": msg})
    return jsonify(resp.json())

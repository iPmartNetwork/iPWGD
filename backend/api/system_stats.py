
from flask import Blueprint, jsonify
from datetime import datetime
import random

stats_bp = Blueprint("system_stats", __name__)

def generate_sample_data(label):
    return [
        {"time": datetime.now().strftime("%H:%M:%S"), "value": random.uniform(10, 80)}
        for _ in range(10)
    ]

@stats_bp.route("/api/system-stats", methods=["GET"])
def get_stats():
    return jsonify({
        "cpu": generate_sample_data("cpu"),
        "ram": generate_sample_data("ram"),
        "network": [
            {"time": datetime.now().strftime("%H:%M:%S"), "tx": random.uniform(1, 20), "rx": random.uniform(1, 20)}
            for _ in range(10)
        ]
    })

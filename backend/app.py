
from flask import Flask
from api.admin_password import admin_bp

app = Flask(__name__)
app.register_blueprint(admin_bp)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=13640)

from api.logs import logs_bp
from api.telegram import telegram_bp

app.register_blueprint(logs_bp)
app.register_blueprint(telegram_bp)

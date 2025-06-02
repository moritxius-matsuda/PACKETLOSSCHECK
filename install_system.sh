#!/bin/bash

# Ping Monitor Installation Script (System-Pakete)
# Alternative Installation mit System-Python-Paketen

set -e

echo "🚀 Ping Monitor Installation gestartet (System-Pakete)..."

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen (sudo ./install_system.sh)"
    exit 1
fi

# Installationsverzeichnis erstellen
INSTALL_DIR="/opt/ping-monitor"
echo "📁 Erstelle Installationsverzeichnis: $INSTALL_DIR"
mkdir -p $INSTALL_DIR

# Python3 und Flask über System-Pakete installieren
echo "🐍 Installiere Python3 und Flask über System-Pakete..."
apt update
apt install -y python3 python3-flask python3-werkzeug

# Dateien kopieren
echo "📋 Kopiere Dateien..."
cp ping_monitor.py $INSTALL_DIR/
cp web_interface.py $INSTALL_DIR/
cp config.py $INSTALL_DIR/
cp -r templates $INSTALL_DIR/
cp requirements.txt $INSTALL_DIR/

# Berechtigungen setzen
echo "🔐 Setze Berechtigungen..."
chmod +x $INSTALL_DIR/ping_monitor.py
chmod +x $INSTALL_DIR/web_interface.py
chown -R root:root $INSTALL_DIR

# Systemd-Service für System-Python erstellen
echo "⚙️ Erstelle Systemd-Service für System-Python..."
cat > /etc/systemd/system/ping-monitor.service << 'EOF'
[Unit]
Description=Ping Monitor Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ping-monitor
ExecStart=/usr/bin/python3 /opt/ping-monitor/web_interface.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Umgebungsvariablen
Environment=PYTHONPATH=/opt/ping-monitor
Environment=FLASK_ENV=production

# Sicherheitseinstellungen
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/ping-monitor

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Service aktivieren und starten
echo "🎯 Aktiviere und starte Service..."
systemctl enable ping-monitor.service
systemctl start ping-monitor.service

# Firewall-Regel für Port 4000 (falls ufw aktiv)
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo "🔥 Öffne Port 4000 in der Firewall..."
    ufw allow 4000/tcp
fi

# Status prüfen
echo "📊 Service-Status:"
systemctl status ping-monitor.service --no-pager

echo ""
echo "✅ Installation abgeschlossen!"
echo ""
echo "📋 Nützliche Befehle:"
echo "   Service-Status:     sudo systemctl status ping-monitor"
echo "   Service stoppen:    sudo systemctl stop ping-monitor"
echo "   Service starten:    sudo systemctl start ping-monitor"
echo "   Service neustarten: sudo systemctl restart ping-monitor"
echo "   Logs anzeigen:      sudo journalctl -u ping-monitor -f"
echo ""
echo "🌐 Web-Interface verfügbar unter: http://$(hostname -I | awk '{print $1}'):4000"
echo "   oder: http://localhost:4000"
echo ""
echo "📁 Installationsverzeichnis: $INSTALL_DIR"
echo "📄 Datenbank-Datei: $INSTALL_DIR/ping_data.db"
echo "📝 Log-Datei: $INSTALL_DIR/ping_monitor.log"
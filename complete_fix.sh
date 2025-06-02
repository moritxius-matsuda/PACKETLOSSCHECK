#!/bin/bash

# Vollständiger Fix für alle Installation-Probleme
# Behebt sowohl das externally-managed-environment als auch das Service-Datei Problem

set -e

echo "🔧 Vollständiger Ping Monitor Fix gestartet..."

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen (sudo ./complete_fix.sh)"
    exit 1
fi

INSTALL_DIR="/opt/ping-monitor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📂 Skript-Verzeichnis: $SCRIPT_DIR"
echo "📁 Installations-Verzeichnis: $INSTALL_DIR"

# Python3 und venv installieren
echo "🐍 Installiere Python3 und venv..."
apt update
apt install -y python3 python3-venv python3-full

# Installationsverzeichnis erstellen
echo "📁 Erstelle Installationsverzeichnis..."
mkdir -p $INSTALL_DIR

# Dateien kopieren
echo "📋 Kopiere alle Dateien..."
cp $SCRIPT_DIR/ping_monitor.py $INSTALL_DIR/
cp $SCRIPT_DIR/web_interface.py $INSTALL_DIR/
cp $SCRIPT_DIR/config.py $INSTALL_DIR/
cp -r $SCRIPT_DIR/templates $INSTALL_DIR/
cp $SCRIPT_DIR/requirements.txt $INSTALL_DIR/

# Virtuelle Umgebung erstellen
echo "🔧 Erstelle virtuelle Python-Umgebung..."
cd $INSTALL_DIR

# Alte venv entfernen falls vorhanden
rm -rf venv

# Neue virtuelle Umgebung erstellen
python3 -m venv venv

# Flask in virtueller Umgebung installieren
echo "📦 Installiere Flask in virtueller Umgebung..."
$INSTALL_DIR/venv/bin/pip install --upgrade pip
$INSTALL_DIR/venv/bin/pip install flask werkzeug

# Berechtigungen setzen
echo "🔐 Setze Berechtigungen..."
chmod +x $INSTALL_DIR/ping_monitor.py
chmod +x $INSTALL_DIR/web_interface.py
chown -R root:root $INSTALL_DIR

# Service-Datei erstellen
echo "⚙️ Erstelle Systemd-Service..."
cat > /etc/systemd/system/ping-monitor.service << 'EOF'
[Unit]
Description=Ping Monitor Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ping-monitor
ExecStart=/opt/ping-monitor/venv/bin/python /opt/ping-monitor/web_interface.py
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

# Systemd neu laden
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
echo "✅ Vollständiger Fix abgeschlossen!"
echo ""
echo "🌐 Web-Interface verfügbar unter:"
echo "   http://localhost:4000"
echo "   http://$(hostname -I | awk '{print $1}'):4000"
echo ""
echo "📋 Nützliche Befehle:"
echo "   Service-Status:     sudo systemctl status ping-monitor"
echo "   Service stoppen:    sudo systemctl stop ping-monitor"
echo "   Service starten:    sudo systemctl start ping-monitor"
echo "   Service neustarten: sudo systemctl restart ping-monitor"
echo "   Logs anzeigen:      sudo journalctl -u ping-monitor -f"
echo ""
echo "📁 Installationsverzeichnis: $INSTALL_DIR"
echo "📄 Datenbank-Datei: $INSTALL_DIR/ping_data.db"
echo "📝 Log-Datei: $INSTALL_DIR/ping_monitor.log"
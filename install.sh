#!/bin/bash

# Ping Monitor Installation Script
# Dieses Skript installiert den Ping Monitor als Linux-Systemdienst

set -e

echo "🚀 Ping Monitor Installation gestartet..."

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen (sudo ./install.sh)"
    exit 1
fi

# Installationsverzeichnis erstellen
INSTALL_DIR="/opt/ping-monitor"
echo "📁 Erstelle Installationsverzeichnis: $INSTALL_DIR"
mkdir -p $INSTALL_DIR

# Python3 und pip prüfen/installieren
echo "🐍 Prüfe Python3 Installation..."
if ! command -v python3 &> /dev/null; then
    echo "📦 Installiere Python3..."
    apt update
    apt install -y python3 python3-pip
fi

# Dateien kopieren
echo "📋 Kopiere Dateien..."
cp ping_monitor.py $INSTALL_DIR/
cp web_interface.py $INSTALL_DIR/
cp -r templates $INSTALL_DIR/
cp requirements.txt $INSTALL_DIR/

# Python-Abhängigkeiten installieren
echo "📦 Installiere Python-Abhängigkeiten..."
cd $INSTALL_DIR
pip3 install -r requirements.txt

# Berechtigungen setzen
echo "🔐 Setze Berechtigungen..."
chmod +x $INSTALL_DIR/ping_monitor.py
chmod +x $INSTALL_DIR/web_interface.py
chown -R root:root $INSTALL_DIR

# Systemd-Service installieren
echo "⚙️ Installiere Systemd-Service..."
cp ping-monitor.service /etc/systemd/system/
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
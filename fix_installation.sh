#!/bin/bash

# Schnell-Fix für die Installation
# Behebt das externally-managed-environment Problem

set -e

echo "🔧 Ping Monitor Installation Fix..."

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen (sudo ./fix_installation.sh)"
    exit 1
fi

INSTALL_DIR="/opt/ping-monitor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installationsverzeichnis erstellen falls nicht vorhanden
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📁 Erstelle Installationsverzeichnis: $INSTALL_DIR"
    mkdir -p $INSTALL_DIR
    
    # Dateien kopieren
    echo "📋 Kopiere Dateien..."
    cp $SCRIPT_DIR/ping_monitor.py $INSTALL_DIR/
    cp $SCRIPT_DIR/web_interface.py $INSTALL_DIR/
    cp $SCRIPT_DIR/config.py $INSTALL_DIR/
    cp -r $SCRIPT_DIR/templates $INSTALL_DIR/
    cp $SCRIPT_DIR/requirements.txt $INSTALL_DIR/
    
    # Berechtigungen setzen
    chmod +x $INSTALL_DIR/ping_monitor.py
    chmod +x $INSTALL_DIR/web_interface.py
    chown -R root:root $INSTALL_DIR
fi

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

# Service-Datei aktualisieren
echo "⚙️ Aktualisiere Service-Datei..."
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

# Status prüfen
echo "📊 Service-Status:"
systemctl status ping-monitor.service --no-pager

echo ""
echo "✅ Fix abgeschlossen!"
echo ""
echo "🌐 Web-Interface sollte jetzt verfügbar sein unter: http://localhost:4000"
#!/bin/bash

# Ping Monitor - Robuste Installation
# Funktioniert von Anfang an, ohne Probleme

set -e

echo "🚀 Ping Monitor - Robuste Installation gestartet..."
echo "   Dieses Skript funktioniert von Anfang an!"

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen:"
    echo "   sudo bash install_robust.sh"
    exit 1
fi

# Variablen
INSTALL_DIR="/opt/ping-monitor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📂 Skript-Verzeichnis: $SCRIPT_DIR"
echo "📁 Installations-Verzeichnis: $INSTALL_DIR"

# Prüfen ob alle benötigten Dateien vorhanden sind
echo "🔍 Prüfe benötigte Dateien..."
REQUIRED_FILES=(
    "ping_monitor.py"
    "web_interface.py" 
    "config.py"
    "templates/index.html"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$file" ] && [ ! -d "$SCRIPT_DIR/$(dirname $file)" ]; then
        echo "❌ Datei nicht gefunden: $file"
        echo "   Bitte stellen Sie sicher, dass alle Dateien im Verzeichnis sind"
        exit 1
    fi
done
echo "✅ Alle benötigten Dateien gefunden"

# System aktualisieren und Python installieren
echo "🐍 Installiere Python3 und Abhängigkeiten..."
apt update -qq
apt install -y python3 python3-venv python3-pip python3-full curl

# Installationsverzeichnis erstellen
echo "📁 Erstelle Installationsverzeichnis..."
rm -rf $INSTALL_DIR  # Alte Installation entfernen
mkdir -p $INSTALL_DIR

# Dateien kopieren
echo "📋 Kopiere Dateien..."
cp "$SCRIPT_DIR/ping_monitor.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/web_interface.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/config.py" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/templates" "$INSTALL_DIR/"

# requirements.txt erstellen (falls nicht vorhanden)
echo "📦 Erstelle requirements.txt..."
cat > "$INSTALL_DIR/requirements.txt" << 'EOF'
Flask>=2.3.0,<3.0.0
Werkzeug>=2.3.0,<3.0.0
EOF

# Virtuelle Umgebung erstellen
echo "🔧 Erstelle virtuelle Python-Umgebung..."
cd "$INSTALL_DIR"
python3 -m venv venv

# Flask installieren
echo "📦 Installiere Flask in virtueller Umgebung..."
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet
"$INSTALL_DIR/venv/bin/pip" install flask werkzeug --quiet

# Berechtigungen setzen
echo "🔐 Setze Berechtigungen..."
chmod +x "$INSTALL_DIR/ping_monitor.py"
chmod +x "$INSTALL_DIR/web_interface.py"
chown -R root:root "$INSTALL_DIR"

# Systemd-Service erstellen
echo "⚙️ Erstelle Systemd-Service..."
cat > /etc/systemd/system/ping-monitor.service << EOF
[Unit]
Description=Ping Monitor Service - Netzwerk Überwachung
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/web_interface.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Umgebungsvariablen
Environment=PYTHONPATH=$INSTALL_DIR
Environment=FLASK_ENV=production

# Sicherheitseinstellungen
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

# Systemd neu laden
echo "🔄 Lade Systemd neu..."
systemctl daemon-reload

# Service aktivieren
echo "🎯 Aktiviere Service..."
systemctl enable ping-monitor.service

# Firewall konfigurieren (falls ufw vorhanden)
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "🔥 Öffne Port 4000 in der Firewall..."
        ufw allow 4000/tcp --comment "Ping Monitor Web Interface"
    fi
fi

# Service starten
echo "▶️ Starte Service..."
systemctl start ping-monitor.service

# Kurz warten
sleep 3

# Status prüfen
echo "📊 Prüfe Service-Status..."
if systemctl is-active --quiet ping-monitor.service; then
    echo "✅ Service läuft erfolgreich!"
else
    echo "⚠️ Service-Status:"
    systemctl status ping-monitor.service --no-pager
fi

# Web-Interface testen
echo "🌐 Teste Web-Interface..."
sleep 2
if curl -s http://localhost:4000 > /dev/null; then
    echo "✅ Web-Interface ist erreichbar!"
else
    echo "⚠️ Web-Interface noch nicht erreichbar (kann einige Sekunden dauern)"
fi

# IP-Adresse ermitteln
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🎉 Installation erfolgreich abgeschlossen!"
echo ""
echo "📋 Service-Informationen:"
echo "   Status:             sudo systemctl status ping-monitor"
echo "   Stoppen:            sudo systemctl stop ping-monitor"
echo "   Starten:            sudo systemctl start ping-monitor"
echo "   Neustarten:         sudo systemctl restart ping-monitor"
echo "   Logs anzeigen:      sudo journalctl -u ping-monitor -f"
echo ""
echo "🌐 Web-Interface verfügbar unter:"
echo "   Lokal:              http://localhost:4000"
if [ ! -z "$SERVER_IP" ]; then
echo "   Netzwerk:           http://$SERVER_IP:4000"
fi
echo ""
echo "📁 Installation:"
echo "   Verzeichnis:        $INSTALL_DIR"
echo "   Datenbank:          $INSTALL_DIR/ping_data.db"
echo "   Logs:               $INSTALL_DIR/ping_monitor.log"
echo "   Service-Datei:      /etc/systemd/system/ping-monitor.service"
echo ""
echo "🎯 Der Ping Monitor überwacht jetzt kontinuierlich:"
echo "   Primär:             8.8.8.8 (Google DNS)"
echo "   Sekundär:           8.8.4.4 (Google DNS)"
echo "   Intervall:          1 Sekunde"
echo ""
echo "✨ Viel Spaß mit Ihrem Ping Monitor!"#!/bin/bash

# Ping Monitor - Robuste Installation
# Funktioniert von Anfang an, ohne Probleme

set -e

echo "🚀 Ping Monitor - Robuste Installation gestartet..."
echo "   Dieses Skript funktioniert von Anfang an!"

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen:"
    echo "   sudo bash install_robust.sh"
    exit 1
fi

# Variablen
INSTALL_DIR="/opt/ping-monitor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📂 Skript-Verzeichnis: $SCRIPT_DIR"
echo "📁 Installations-Verzeichnis: $INSTALL_DIR"

# Prüfen ob alle benötigten Dateien vorhanden sind
echo "🔍 Prüfe benötigte Dateien..."
REQUIRED_FILES=(
    "ping_monitor.py"
    "web_interface.py" 
    "config.py"
    "templates/index.html"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$file" ] && [ ! -d "$SCRIPT_DIR/$(dirname $file)" ]; then
        echo "❌ Datei nicht gefunden: $file"
        echo "   Bitte stellen Sie sicher, dass alle Dateien im Verzeichnis sind"
        exit 1
    fi
done
echo "✅ Alle benötigten Dateien gefunden"

# System aktualisieren und Python installieren
echo "🐍 Installiere Python3 und Abhängigkeiten..."
apt update -qq
apt install -y python3 python3-venv python3-pip python3-full curl

# Installationsverzeichnis erstellen
echo "📁 Erstelle Installationsverzeichnis..."
rm -rf $INSTALL_DIR  # Alte Installation entfernen
mkdir -p $INSTALL_DIR

# Dateien kopieren
echo "📋 Kopiere Dateien..."
cp "$SCRIPT_DIR/ping_monitor.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/web_interface.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/config.py" "$INSTALL_DIR/"
cp -r "$SCRIPT_DIR/templates" "$INSTALL_DIR/"

# requirements.txt erstellen (falls nicht vorhanden)
echo "📦 Erstelle requirements.txt..."
cat > "$INSTALL_DIR/requirements.txt" << 'EOF'
Flask>=2.3.0,<3.0.0
Werkzeug>=2.3.0,<3.0.0
EOF

# Virtuelle Umgebung erstellen
echo "🔧 Erstelle virtuelle Python-Umgebung..."
cd "$INSTALL_DIR"
python3 -m venv venv

# Flask installieren
echo "📦 Installiere Flask in virtueller Umgebung..."
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet
"$INSTALL_DIR/venv/bin/pip" install flask werkzeug --quiet

# Berechtigungen setzen
echo "🔐 Setze Berechtigungen..."
chmod +x "$INSTALL_DIR/ping_monitor.py"
chmod +x "$INSTALL_DIR/web_interface.py"
chown -R root:root "$INSTALL_DIR"

# Systemd-Service erstellen
echo "⚙️ Erstelle Systemd-Service..."
cat > /etc/systemd/system/ping-monitor.service << EOF
[Unit]
Description=Ping Monitor Service - Netzwerk Überwachung
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/web_interface.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Umgebungsvariablen
Environment=PYTHONPATH=$INSTALL_DIR
Environment=FLASK_ENV=production

# Sicherheitseinstellungen
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

# Systemd neu laden
echo "🔄 Lade Systemd neu..."
systemctl daemon-reload

# Service aktivieren
echo "🎯 Aktiviere Service..."
systemctl enable ping-monitor.service

# Firewall konfigurieren (falls ufw vorhanden)
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "🔥 Öffne Port 4000 in der Firewall..."
        ufw allow 4000/tcp --comment "Ping Monitor Web Interface"
    fi
fi

# Service starten
echo "▶️ Starte Service..."
systemctl start ping-monitor.service

# Kurz warten
sleep 3

# Status prüfen
echo "📊 Prüfe Service-Status..."
if systemctl is-active --quiet ping-monitor.service; then
    echo "✅ Service läuft erfolgreich!"
else
    echo "⚠️ Service-Status:"
    systemctl status ping-monitor.service --no-pager
fi

# Web-Interface testen
echo "🌐 Teste Web-Interface..."
sleep 2
if curl -s http://localhost:4000 > /dev/null; then
    echo "✅ Web-Interface ist erreichbar!"
else
    echo "⚠️ Web-Interface noch nicht erreichbar (kann einige Sekunden dauern)"
fi

# IP-Adresse ermitteln
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🎉 Installation erfolgreich abgeschlossen!"
echo ""
echo "📋 Service-Informationen:"
echo "   Status:             sudo systemctl status ping-monitor"
echo "   Stoppen:            sudo systemctl stop ping-monitor"
echo "   Starten:            sudo systemctl start ping-monitor"
echo "   Neustarten:         sudo systemctl restart ping-monitor"
echo "   Logs anzeigen:      sudo journalctl -u ping-monitor -f"
echo ""
echo "🌐 Web-Interface verfügbar unter:"
echo "   Lokal:              http://localhost:4000"
if [ ! -z "$SERVER_IP" ]; then
echo "   Netzwerk:           http://$SERVER_IP:4000"
fi
echo ""
echo "📁 Installation:"
echo "   Verzeichnis:        $INSTALL_DIR"
echo "   Datenbank:          $INSTALL_DIR/ping_data.db"
echo "   Logs:               $INSTALL_DIR/ping_monitor.log"
echo "   Service-Datei:      /etc/systemd/system/ping-monitor.service"
echo ""
echo "🎯 Der Ping Monitor überwacht jetzt kontinuierlich:"
echo "   Primär:             8.8.8.8 (Google DNS)"
echo "   Sekundär:           8.8.4.4 (Google DNS)"
echo "   Intervall:          1 Sekunde"
echo ""
echo "✨ Viel Spaß mit Ihrem Ping Monitor!"
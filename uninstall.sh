#!/bin/bash

# Ping Monitor Uninstall Script
# Entfernt den Ping Monitor Service vollständig

set -e

echo "🗑️ Ping Monitor Deinstallation gestartet..."

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen (sudo ./uninstall.sh)"
    exit 1
fi

# Service stoppen und deaktivieren
echo "⏹️ Stoppe und deaktiviere Service..."
if systemctl is-active --quiet ping-monitor; then
    systemctl stop ping-monitor.service
fi

if systemctl is-enabled --quiet ping-monitor; then
    systemctl disable ping-monitor.service
fi

# Service-Datei entfernen
echo "🗂️ Entferne Service-Datei..."
if [ -f "/etc/systemd/system/ping-monitor.service" ]; then
    rm /etc/systemd/system/ping-monitor.service
    systemctl daemon-reload
fi

# Installationsverzeichnis entfernen
INSTALL_DIR="/opt/ping-monitor"
if [ -d "$INSTALL_DIR" ]; then
    echo "📁 Entferne Installationsverzeichnis: $INSTALL_DIR"
    
    # Backup der Datenbank anbieten
    if [ -f "$INSTALL_DIR/ping_data.db" ]; then
        echo "💾 Datenbank gefunden. Backup erstellen? (j/n)"
        read -r response
        if [[ "$response" =~ ^[Jj]$ ]]; then
            BACKUP_DIR="$HOME/ping-monitor-backup-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            cp "$INSTALL_DIR/ping_data.db" "$BACKUP_DIR/"
            cp "$INSTALL_DIR/ping_monitor.log" "$BACKUP_DIR/" 2>/dev/null || true
            echo "💾 Backup erstellt in: $BACKUP_DIR"
        fi
    fi
    
    rm -rf "$INSTALL_DIR"
fi

# Firewall-Regel entfernen (falls ufw aktiv)
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo "🔥 Entferne Firewall-Regel für Port 4000..."
    ufw delete allow 4000/tcp 2>/dev/null || true
fi

echo ""
echo "✅ Deinstallation abgeschlossen!"
echo ""
echo "📋 Was wurde entfernt:"
echo "   ✓ Systemd-Service"
echo "   ✓ Installationsverzeichnis /opt/ping-monitor"
echo "   ✓ Firewall-Regel für Port 4000"
echo ""
echo "💡 Python-Abhängigkeiten (Flask) wurden NICHT entfernt."
echo "   Zum Entfernen: pip3 uninstall flask"
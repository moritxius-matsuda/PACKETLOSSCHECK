# Ping Monitor Makefile
# Vereinfacht die Verwaltung des Ping Monitor Services

.PHONY: help install uninstall start stop restart status logs test clean

# Standardziel
help:
	@echo "🌐 Ping Monitor - Verfügbare Befehle:"
	@echo ""
	@echo "  📦 Installation:"
	@echo "    make install     - Installiert den Service"
	@echo "    make uninstall   - Deinstalliert den Service"
	@echo ""
	@echo "  🎮 Service-Kontrolle:"
	@echo "    make start       - Startet den Service"
	@echo "    make stop        - Stoppt den Service"
	@echo "    make restart     - Startet den Service neu"
	@echo "    make status      - Zeigt Service-Status"
	@echo "    make logs        - Zeigt Live-Logs"
	@echo ""
	@echo "  🧪 Entwicklung:"
	@echo "    make test        - Führt Tests aus"
	@echo "    make dev         - Startet Entwicklungsserver"
	@echo "    make clean       - Bereinigt temporäre Dateien"
	@echo ""
	@echo "  📊 Monitoring:"
	@echo "    make web         - Öffnet Web-Interface"
	@echo "    make backup      - Erstellt Datenbank-Backup"

# Installation
install:
	@echo "📦 Installiere Ping Monitor..."
	@chmod +x install.sh
	@sudo ./install.sh

uninstall:
	@echo "🗑️ Deinstalliere Ping Monitor..."
	@chmod +x uninstall.sh
	@sudo ./uninstall.sh

# Service-Kontrolle
start:
	@echo "▶️ Starte Ping Monitor Service..."
	@sudo systemctl start ping-monitor.service
	@sudo systemctl status ping-monitor.service --no-pager

stop:
	@echo "⏹️ Stoppe Ping Monitor Service..."
	@sudo systemctl stop ping-monitor.service

restart:
	@echo "🔄 Starte Ping Monitor Service neu..."
	@sudo systemctl restart ping-monitor.service
	@sudo systemctl status ping-monitor.service --no-pager

status:
	@echo "📊 Ping Monitor Service Status:"
	@sudo systemctl status ping-monitor.service --no-pager

logs:
	@echo "📝 Ping Monitor Live-Logs (Ctrl+C zum Beenden):"
	@sudo journalctl -u ping-monitor -f

# Entwicklung
test:
	@echo "🧪 Führe Tests aus..."
	@python3 test_local.py test

dev:
	@echo "🚀 Starte Entwicklungsserver..."
	@python3 test_local.py server

clean:
	@echo "🧹 Bereinige temporäre Dateien..."
	@python3 test_local.py cleanup
	@rm -f *.pyc
	@rm -rf __pycache__
	@echo "✅ Bereinigung abgeschlossen"

# Monitoring
web:
	@echo "🌐 Öffne Web-Interface..."
	@python3 -c "import webbrowser; webbrowser.open('http://localhost:4000')"

backup:
	@echo "💾 Erstelle Datenbank-Backup..."
	@mkdir -p backups
	@cp /opt/ping-monitor/ping_data.db backups/ping_data_backup_$(shell date +%Y%m%d_%H%M%S).db 2>/dev/null || \
	 cp ping_data.db backups/ping_data_backup_$(shell date +%Y%m%d_%H%M%S).db 2>/dev/null || \
	 echo "❌ Keine Datenbank gefunden"
	@echo "✅ Backup erstellt in backups/"

# Abhängigkeiten prüfen
check-deps:
	@echo "🔍 Prüfe Abhängigkeiten..."
	@python3 -c "import flask; print('✅ Flask verfügbar')" || echo "❌ Flask nicht installiert"
	@python3 -c "import sqlite3; print('✅ SQLite verfügbar')" || echo "❌ SQLite nicht verfügbar"
	@which ping > /dev/null && echo "✅ Ping verfügbar" || echo "❌ Ping nicht verfügbar"

# Konfiguration anzeigen
config:
	@echo "📋 Aktuelle Konfiguration:"
	@python3 -c "from config import Config; Config.print_config()"

# Service-Informationen
info:
	@echo "ℹ️ Ping Monitor Informationen:"
	@echo "   Service-Datei: /etc/systemd/system/ping-monitor.service"
	@echo "   Installation: /opt/ping-monitor/"
	@echo "   Datenbank: /opt/ping-monitor/ping_data.db"
	@echo "   Logs: /opt/ping-monitor/ping_monitor.log"
	@echo "   Web-Interface: http://localhost:4000"

# Vollständige Neuinstallation
reinstall: uninstall install
	@echo "🔄 Neuinstallation abgeschlossen"
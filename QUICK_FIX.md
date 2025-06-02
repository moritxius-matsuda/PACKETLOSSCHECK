# 🚨 Schnell-Fix für "externally-managed-environment" Fehler

## Problem
Sie erhalten den Fehler:
```
error: externally-managed-environment
× This environment is externally managed
```

## 🔧 Sofortige Lösung

### Option 1: Vollständiger Fix (Empfohlen)
```bash
chmod +x complete_fix.sh
sudo ./complete_fix.sh
```

### Option 2: Fix-Skript ausführen
```bash
chmod +x fix_installation.sh
sudo ./fix_installation.sh
```

### Option 3: System-Pakete verwenden
```bash
chmod +x install_system.sh
sudo ./install_system.sh
```

### Option 4: Makefile verwenden
```bash
make complete-fix
# oder
make fix
```

### Option 4: Manuelle Lösung
```bash
# 1. Virtuelle Umgebung erstellen
cd /opt/ping-monitor
sudo python3 -m venv venv

# 2. Flask installieren
sudo /opt/ping-monitor/venv/bin/pip install flask werkzeug

# 3. Service-Datei aktualisieren
sudo nano /etc/systemd/system/ping-monitor.service
# Ändere die ExecStart-Zeile zu:
# ExecStart=/opt/ping-monitor/venv/bin/python /opt/ping-monitor/web_interface.py

# 4. Service neu laden und starten
sudo systemctl daemon-reload
sudo systemctl enable ping-monitor.service
sudo systemctl start ping-monitor.service
```

## ✅ Überprüfung

Nach dem Fix:
```bash
# Service-Status prüfen
sudo systemctl status ping-monitor

# Web-Interface testen
curl http://localhost:4000

# Logs anzeigen
sudo journalctl -u ping-monitor -f
```

## 🌐 Web-Interface

Nach erfolgreichem Fix sollte das Web-Interface verfügbar sein unter:
- http://localhost:4000
- http://your-server-ip:4000

## 📞 Weitere Hilfe

Falls Probleme bestehen:
1. Logs prüfen: `sudo journalctl -u ping-monitor -n 50`
2. Manuell testen: `cd /opt/ping-monitor && sudo ./venv/bin/python web_interface.py`
3. Firewall prüfen: `sudo ufw status`
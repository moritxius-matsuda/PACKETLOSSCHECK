# 🌐 Ping Monitor Service

Ein Python-basierter Ping-Monitor-Service für Linux, der kontinuierlich die Netzwerkverbindung überwacht und eine schöne Web-Oberfläche bereitstellt.

## ✨ Features

- **Kontinuierliches Ping-Monitoring**: Sendet jede Sekunde einen Ping an 8.8.8.8 (primär) oder 8.8.4.4 (sekundär)
- **Automatischer Failover**: Wechselt automatisch zwischen den Hosts bei Verbindungsproblemen
- **Packet Loss Berechnung**: Berechnet und verfolgt die Paketverlustrate
- **Web-Dashboard**: Schöne, responsive Web-Oberfläche auf Port 4000
- **Datenbank-Logging**: SQLite-Datenbank für historische Daten
- **Linux-Systemdienst**: Läuft als systemd-Service im Hintergrund
- **Real-time Updates**: Live-Aktualisierung der Web-Oberfläche

## 🚀 Installation

### Automatische Installation

1. **Dateien herunterladen und Installation ausführen**:
   ```bash
   # Einfach und funktioniert von Anfang an:
   sudo bash install.sh
   ```

Das war's! Das Skript:
- ✅ Prüft alle Abhängigkeiten
- ✅ Installiert Python3 und Flask automatisch
- ✅ Erstellt virtuelle Umgebung
- ✅ Konfiguriert den Service
- ✅ Startet alles automatisch
- ✅ Testet die Installation

**Alternative Installationsmethoden** (falls benötigt):
- **System-Pakete**: `sudo bash install_system.sh`
- **Makefile**: `make install`

Das Installationsskript führt automatisch folgende Schritte aus:
- Installiert Python3 und pip (falls nicht vorhanden)
- Kopiert alle Dateien nach `/opt/ping-monitor`
- Installiert Python-Abhängigkeiten
- Richtet den systemd-Service ein
- Startet den Service automatisch
- Öffnet Port 4000 in der Firewall (falls ufw aktiv)

### Manuelle Installation

1. **Abhängigkeiten installieren**:
   ```bash
   sudo apt update
   sudo apt install python3 python3-pip
   pip3 install flask
   ```

2. **Dateien kopieren**:
   ```bash
   sudo mkdir -p /opt/ping-monitor
   sudo cp *.py /opt/ping-monitor/
   sudo cp -r templates /opt/ping-monitor/
   sudo cp requirements.txt /opt/ping-monitor/
   ```

3. **Service einrichten**:
   ```bash
   sudo cp ping-monitor.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable ping-monitor.service
   sudo systemctl start ping-monitor.service
   ```

## 🎯 Verwendung

### Web-Interface

Nach der Installation ist das Web-Dashboard verfügbar unter:
- `http://localhost:4000`
- `http://<server-ip>:4000`

Das Dashboard zeigt:
- **Aktuelle Packet Loss Rate**
- **Aktueller Ping-Host** (8.8.8.8 oder 8.8.4.4)
- **Gesamtanzahl der Pings**
- **Anzahl fehlgeschlagener Pings**
- **Live-Charts** für Packet Loss und Response Time
- **Live-Log** der letzten Ping-Ergebnisse

### Service-Verwaltung

```bash
# Service-Status prüfen
sudo systemctl status ping-monitor

# Service stoppen
sudo systemctl stop ping-monitor

# Service starten
sudo systemctl start ping-monitor

# Service neustarten
sudo systemctl restart ping-monitor

# Logs anzeigen
sudo journalctl -u ping-monitor -f
```

### API-Endpunkte

Der Service stellt folgende API-Endpunkte bereit:

- `GET /api/stats` - Aktuelle Statistiken
- `GET /api/history?hours=24` - Historische Daten
- `GET /api/summary` - Zusammenfassung der letzten 24h
- `GET /api/control/start` - Monitor starten
- `GET /api/control/stop` - Monitor stoppen
- `GET /api/control/status` - Monitor-Status

## 📊 Funktionsweise

### Ping-Logik

1. **Primärer Host**: Standardmäßig wird 8.8.8.8 (Google DNS) angepingt
2. **Failover**: Nach 3 aufeinanderfolgenden Fehlern wechselt das System zu 8.8.4.4
3. **Timing**: Ein Ping pro Sekunde mit 3-Sekunden-Timeout
4. **Packet Loss**: Wird kontinuierlich basierend auf allen gesendeten Pings berechnet

### Datenbank-Schema

**ping_results Tabelle**:
- `id`: Eindeutige ID
- `timestamp`: Zeitstempel des Pings
- `host`: Gepingter Host (8.8.8.8 oder 8.8.4.4)
- `success`: Erfolg/Fehlschlag (Boolean)
- `response_time`: Antwortzeit in ms
- `packet_loss_percent`: Aktuelle Packet Loss Rate

**statistics Tabelle**:
- `id`: Eindeutige ID
- `timestamp`: Zeitstempel
- `total_pings`: Gesamtanzahl Pings
- `failed_pings`: Anzahl fehlgeschlagener Pings
- `packet_loss_percent`: Packet Loss Rate
- `current_host`: Aktueller Host

## 📁 Dateien und Verzeichnisse

```
/opt/ping-monitor/
├── ping_monitor.py      # Haupt-Monitor-Klasse
├── web_interface.py     # Flask-Web-Interface
├── templates/
│   └── index.html      # Web-Dashboard
├── requirements.txt     # Python-Abhängigkeiten
├── ping_data.db        # SQLite-Datenbank (wird erstellt)
└── ping_monitor.log    # Log-Datei (wird erstellt)
```

## 🔧 Konfiguration

### Ping-Hosts ändern

In `ping_monitor.py` können die Hosts angepasst werden:

```python
self.primary_host = "8.8.8.8"      # Primärer Host
self.secondary_host = "8.8.4.4"    # Sekundärer Host
```

### Port ändern

In `web_interface.py` kann der Port geändert werden:

```python
app.run(host='0.0.0.0', port=4000, debug=False)
```

### Ping-Intervall ändern

In `ping_monitor.py` kann das Intervall angepasst werden:

```python
sleep_time = max(0, 1.0 - elapsed)  # 1 Sekunde
```

## 🛠️ Troubleshooting

### "externally-managed-environment" Fehler

Wenn Sie den Fehler "externally-managed-environment" erhalten:

```bash
# Lösung 1: Fix-Skript ausführen
sudo ./fix_installation.sh

# Lösung 2: System-Pakete verwenden
sudo ./install_system.sh

# Lösung 3: Makefile verwenden
make fix
```

### Service startet nicht

```bash
# Logs prüfen
sudo journalctl -u ping-monitor -n 50

# Manuell testen (virtuelle Umgebung)
cd /opt/ping-monitor
./venv/bin/python web_interface.py

# Manuell testen (System-Python)
cd /opt/ping-monitor
python3 web_interface.py
```

### Port 4000 nicht erreichbar

```bash
# Firewall prüfen
sudo ufw status

# Port öffnen
sudo ufw allow 4000/tcp

# Prozess prüfen
sudo netstat -tlnp | grep :4000
```

### Ping-Berechtigungen

Der Service benötigt Root-Rechte für ICMP-Pings. Alternativ kann `setcap` verwendet werden:

```bash
sudo setcap cap_net_raw+ep /usr/bin/python3
```

## 📈 Performance

- **CPU-Verbrauch**: Minimal (~0.1% auf modernen Systemen)
- **RAM-Verbrauch**: ~20-50 MB
- **Netzwerk**: ~1 Ping pro Sekunde (minimal)
- **Speicher**: SQLite-Datenbank wächst langsam (~1MB pro Tag)

## 🔒 Sicherheit

- Service läuft mit minimalen Berechtigungen
- Nur Port 4000 wird geöffnet
- Keine externen Abhängigkeiten außer Flask
- Lokale SQLite-Datenbank

## 📝 Lizenz

Dieses Projekt steht unter der MIT-Lizenz.

## 🤝 Beitragen

Beiträge sind willkommen! Bitte erstellen Sie einen Pull Request oder öffnen Sie ein Issue.

## 📞 Support

Bei Problemen oder Fragen erstellen Sie bitte ein Issue im Repository.
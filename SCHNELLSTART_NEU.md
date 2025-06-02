# 🚀 Ping Monitor - Schnellstart

## Ein Befehl - Fertig!

```bash
sudo bash install.sh
```

Das war's! 🎉

## Was passiert automatisch:

1. ✅ **Python3 Installation** - Falls nicht vorhanden
2. ✅ **Virtuelle Umgebung** - Saubere Installation
3. ✅ **Flask Installation** - Web-Framework
4. ✅ **Service-Erstellung** - Läuft automatisch im Hintergrund
5. ✅ **Firewall-Konfiguration** - Port 4000 wird geöffnet
6. ✅ **Automatischer Start** - Service startet sofort
7. ✅ **Funktionstest** - Prüft ob alles läuft

## Nach der Installation:

### 🌐 Web-Interface öffnen:
- **Lokal**: http://localhost:4000
- **Netzwerk**: http://your-server-ip:4000

### 📊 Service verwalten:
```bash
# Status prüfen
sudo systemctl status ping-monitor

# Logs anzeigen
sudo journalctl -u ping-monitor -f

# Service neustarten
sudo systemctl restart ping-monitor
```

## 🎯 Was wird überwacht:

- **Primärer Host**: 8.8.8.8 (Google DNS)
- **Sekundärer Host**: 8.8.4.4 (Google DNS)
- **Ping-Intervall**: 1 Sekunde
- **Automatischer Failover**: Bei 3 aufeinanderfolgenden Fehlern

## 📈 Dashboard-Features:

- **Live Packet Loss Rate**
- **Response Time Charts**
- **Ping-Verlauf**
- **Automatische Updates alle 2 Sekunden**
- **Mobile-freundlich**

## 🛠️ Bei Problemen:

```bash
# Logs prüfen
sudo journalctl -u ping-monitor -n 50

# Service manuell testen
cd /opt/ping-monitor
sudo ./venv/bin/python web_interface.py
```

## 🗑️ Deinstallation:

```bash
sudo bash uninstall.sh
```

---

**Das war's! Ihr Ping Monitor läuft jetzt und überwacht kontinuierlich Ihre Netzwerkverbindung.** 🌐✨
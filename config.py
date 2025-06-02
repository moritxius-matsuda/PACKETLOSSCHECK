#!/usr/bin/env python3
"""
Konfigurationsdatei für Ping Monitor
Zentrale Stelle für alle Einstellungen
"""

import os

class Config:
    """Konfigurationsklasse für Ping Monitor"""
    
    # Ping-Einstellungen
    PRIMARY_HOST = "8.8.8.8"           # Primärer Ping-Host (Google DNS)
    SECONDARY_HOST = "8.8.4.4"         # Sekundärer Ping-Host (Google DNS)
    PING_INTERVAL = 1.0                 # Ping-Intervall in Sekunden
    PING_TIMEOUT = 3                    # Ping-Timeout in Sekunden
    FAILOVER_THRESHOLD = 3              # Anzahl Fehlschläge vor Failover
    
    # Web-Interface Einstellungen
    WEB_HOST = "0.0.0.0"               # Web-Server Host (0.0.0.0 = alle Interfaces)
    WEB_PORT = 4000                     # Web-Server Port
    DEBUG_MODE = False                  # Debug-Modus für Flask
    
    # Datenbank-Einstellungen
    DATABASE_PATH = "ping_data.db"      # Pfad zur SQLite-Datenbank
    MAX_RECENT_PINGS = 3600            # Maximale Anzahl recent pings im Speicher (1 Stunde)
    STATS_SAVE_INTERVAL = 60           # Statistiken alle X Pings speichern
    
    # Logging-Einstellungen
    LOG_LEVEL = "INFO"                 # Log-Level (DEBUG, INFO, WARNING, ERROR)
    LOG_FILE = "ping_monitor.log"      # Log-Datei
    LOG_MAX_SIZE = 10 * 1024 * 1024   # Maximale Log-Dateigröße (10MB)
    LOG_BACKUP_COUNT = 5               # Anzahl Log-Backup-Dateien
    
    # Chart-Einstellungen
    CHART_MAX_POINTS = 50              # Maximale Punkte in Charts
    CHART_UPDATE_INTERVAL = 2000       # Chart-Update-Intervall in ms
    
    # Erweiterte Einstellungen
    ENABLE_EMAIL_ALERTS = False        # E-Mail-Benachrichtigungen aktivieren
    EMAIL_SMTP_SERVER = "smtp.gmail.com"
    EMAIL_SMTP_PORT = 587
    EMAIL_USERNAME = ""
    EMAIL_PASSWORD = ""
    EMAIL_TO = ""
    ALERT_THRESHOLD = 10.0             # Packet Loss Schwellwert für Alerts (%)
    
    # Performance-Einstellungen
    DATABASE_CLEANUP_DAYS = 30         # Alte Daten nach X Tagen löschen
    ENABLE_DATABASE_CLEANUP = True     # Automatische Datenbankbereinigung
    
    @classmethod
    def load_from_env(cls):
        """Lädt Konfiguration aus Umgebungsvariablen"""
        cls.PRIMARY_HOST = os.getenv('PING_PRIMARY_HOST', cls.PRIMARY_HOST)
        cls.SECONDARY_HOST = os.getenv('PING_SECONDARY_HOST', cls.SECONDARY_HOST)
        cls.PING_INTERVAL = float(os.getenv('PING_INTERVAL', cls.PING_INTERVAL))
        cls.WEB_PORT = int(os.getenv('WEB_PORT', cls.WEB_PORT))
        cls.WEB_HOST = os.getenv('WEB_HOST', cls.WEB_HOST)
        cls.DATABASE_PATH = os.getenv('DATABASE_PATH', cls.DATABASE_PATH)
        cls.LOG_LEVEL = os.getenv('LOG_LEVEL', cls.LOG_LEVEL)
        cls.DEBUG_MODE = os.getenv('DEBUG_MODE', 'False').lower() == 'true'
    
    @classmethod
    def validate(cls):
        """Validiert die Konfiguration"""
        errors = []
        
        if cls.PING_INTERVAL <= 0:
            errors.append("PING_INTERVAL muss größer als 0 sein")
        
        if cls.WEB_PORT < 1 or cls.WEB_PORT > 65535:
            errors.append("WEB_PORT muss zwischen 1 und 65535 liegen")
        
        if cls.PING_TIMEOUT <= 0:
            errors.append("PING_TIMEOUT muss größer als 0 sein")
        
        if cls.FAILOVER_THRESHOLD <= 0:
            errors.append("FAILOVER_THRESHOLD muss größer als 0 sein")
        
        if errors:
            raise ValueError("Konfigurationsfehler: " + ", ".join(errors))
        
        return True
    
    @classmethod
    def print_config(cls):
        """Gibt die aktuelle Konfiguration aus"""
        print("📋 Aktuelle Konfiguration:")
        print(f"   Primärer Host: {cls.PRIMARY_HOST}")
        print(f"   Sekundärer Host: {cls.SECONDARY_HOST}")
        print(f"   Ping-Intervall: {cls.PING_INTERVAL}s")
        print(f"   Ping-Timeout: {cls.PING_TIMEOUT}s")
        print(f"   Failover-Schwellwert: {cls.FAILOVER_THRESHOLD}")
        print(f"   Web-Server: {cls.WEB_HOST}:{cls.WEB_PORT}")
        print(f"   Datenbank: {cls.DATABASE_PATH}")
        print(f"   Log-Level: {cls.LOG_LEVEL}")
        print(f"   Debug-Modus: {cls.DEBUG_MODE}")

# Konfiguration beim Import laden
Config.load_from_env()

# Alternative Konfigurationen für verschiedene Umgebungen
class DevelopmentConfig(Config):
    """Entwicklungs-Konfiguration"""
    DEBUG_MODE = True
    LOG_LEVEL = "DEBUG"
    DATABASE_PATH = "dev_ping_data.db"
    WEB_HOST = "127.0.0.1"

class ProductionConfig(Config):
    """Produktions-Konfiguration"""
    DEBUG_MODE = False
    LOG_LEVEL = "INFO"
    ENABLE_DATABASE_CLEANUP = True

class TestConfig(Config):
    """Test-Konfiguration"""
    DATABASE_PATH = "test_ping_data.db"
    PING_INTERVAL = 0.1  # Schnellere Tests
    MAX_RECENT_PINGS = 100
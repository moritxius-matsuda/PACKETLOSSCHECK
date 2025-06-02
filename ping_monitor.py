#!/usr/bin/env python3
"""
Ping Monitor Service
Überwacht kontinuierlich die Netzwerkverbindung durch Pings an 8.8.8.8 und 8.8.4.4
"""

import time
import subprocess
import threading
import json
import logging
from datetime import datetime, timedelta
from collections import deque
import sqlite3
import os
import signal
import sys
from config import Config

class PingMonitor:
    def __init__(self, db_path=None):
        # Konfiguration laden
        Config.validate()
        
        self.primary_host = Config.PRIMARY_HOST
        self.secondary_host = Config.SECONDARY_HOST
        self.current_host = self.primary_host
        self.db_path = db_path or Config.DATABASE_PATH
        self.running = False
        self.ping_interval = Config.PING_INTERVAL
        self.ping_timeout = Config.PING_TIMEOUT
        self.failover_threshold = Config.FAILOVER_THRESHOLD
        
        # Statistiken
        self.total_pings = 0
        self.failed_pings = 0
        self.recent_pings = deque(maxlen=Config.MAX_RECENT_PINGS)
        
        # Packet Loss Event Tracking
        self.current_loss_event = None
        self.consecutive_failures = 0
        
        # Setup logging
        log_level = getattr(logging, Config.LOG_LEVEL.upper())
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(Config.LOG_FILE),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Setup database
        self.init_database()
        
        # Signal handler für graceful shutdown
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
    
    def init_database(self):
        """Initialisiert die SQLite-Datenbank"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS ping_results (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    host TEXT NOT NULL,
                    success BOOLEAN NOT NULL,
                    response_time REAL,
                    packet_loss_percent REAL
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS statistics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    total_pings INTEGER,
                    failed_pings INTEGER,
                    packet_loss_percent REAL,
                    current_host TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS packet_loss_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    start_time DATETIME NOT NULL,
                    end_time DATETIME,
                    host TEXT NOT NULL,
                    consecutive_failures INTEGER,
                    duration_seconds INTEGER,
                    is_active BOOLEAN DEFAULT 1
                )
            ''')
            
            conn.commit()
            conn.close()
            self.logger.info("Datenbank initialisiert")
        except Exception as e:
            self.logger.error(f"Fehler beim Initialisieren der Datenbank: {e}")
    
    def ping_host(self, host):
        """Führt einen Ping zu einem Host aus"""
        try:
            # Linux ping command
            result = subprocess.run(
                ['ping', '-c', '1', '-W', str(self.ping_timeout), host],
                capture_output=True,
                text=True,
                timeout=self.ping_timeout + 2
            )
            
            if result.returncode == 0:
                # Parse response time from output
                output = result.stdout
                if 'time=' in output:
                    time_str = output.split('time=')[1].split(' ')[0]
                    response_time = float(time_str)
                    return True, response_time
                return True, 0.0
            else:
                return False, None
                
        except subprocess.TimeoutExpired:
            self.logger.warning(f"Ping timeout für {host}")
            return False, None
        except Exception as e:
            self.logger.error(f"Ping-Fehler für {host}: {e}")
            return False, None
    
    def switch_host(self):
        """Wechselt zwischen primärem und sekundärem Host"""
        if self.current_host == self.primary_host:
            self.current_host = self.secondary_host
            self.logger.info(f"Wechsel zu sekundärem Host: {self.secondary_host}")
        else:
            self.current_host = self.primary_host
            self.logger.info(f"Wechsel zu primärem Host: {self.primary_host}")
    
    def calculate_packet_loss(self):
        """Berechnet den aktuellen Packet Loss"""
        if self.total_pings == 0:
            return 0.0
        return (self.failed_pings / self.total_pings) * 100
    
    def save_ping_result(self, host, success, response_time):
        """Speichert Ping-Ergebnis in der Datenbank"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            packet_loss = self.calculate_packet_loss()
            
            cursor.execute('''
                INSERT INTO ping_results (host, success, response_time, packet_loss_percent)
                VALUES (?, ?, ?, ?)
            ''', (host, success, response_time, packet_loss))
            
            conn.commit()
            conn.close()
        except Exception as e:
            self.logger.error(f"Fehler beim Speichern der Ping-Ergebnisse: {e}")
    
    def save_statistics(self):
        """Speichert aktuelle Statistiken"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            packet_loss = self.calculate_packet_loss()
            
            cursor.execute('''
                INSERT INTO statistics (total_pings, failed_pings, packet_loss_percent, current_host)
                VALUES (?, ?, ?, ?)
            ''', (self.total_pings, self.failed_pings, packet_loss, self.current_host))
            
            conn.commit()
            conn.close()
        except Exception as e:
            self.logger.error(f"Fehler beim Speichern der Statistiken: {e}")
    
    def start_packet_loss_event(self):
        """Startet ein neues Packet Loss Event"""
        if self.current_loss_event is None:
            self.current_loss_event = {
                'start_time': datetime.now(),
                'host': self.current_host,
                'consecutive_failures': 1
            }
            
            try:
                conn = sqlite3.connect(self.db_path)
                cursor = conn.cursor()
                
                cursor.execute('''
                    INSERT INTO packet_loss_events (start_time, host, consecutive_failures)
                    VALUES (?, ?, ?)
                ''', (self.current_loss_event['start_time'], self.current_loss_event['host'], 1))
                
                self.current_loss_event['id'] = cursor.lastrowid
                conn.commit()
                conn.close()
                
                self.logger.warning(f"Packet Loss Event gestartet für {self.current_host}")
            except Exception as e:
                self.logger.error(f"Fehler beim Starten des Packet Loss Events: {e}")
    
    def update_packet_loss_event(self):
        """Aktualisiert das aktuelle Packet Loss Event"""
        if self.current_loss_event:
            self.current_loss_event['consecutive_failures'] += 1
            
            try:
                conn = sqlite3.connect(self.db_path)
                cursor = conn.cursor()
                
                cursor.execute('''
                    UPDATE packet_loss_events 
                    SET consecutive_failures = ?
                    WHERE id = ?
                ''', (self.current_loss_event['consecutive_failures'], self.current_loss_event['id']))
                
                conn.commit()
                conn.close()
            except Exception as e:
                self.logger.error(f"Fehler beim Aktualisieren des Packet Loss Events: {e}")
    
    def end_packet_loss_event(self):
        """Beendet das aktuelle Packet Loss Event"""
        if self.current_loss_event:
            end_time = datetime.now()
            duration = (end_time - self.current_loss_event['start_time']).total_seconds()
            
            try:
                conn = sqlite3.connect(self.db_path)
                cursor = conn.cursor()
                
                cursor.execute('''
                    UPDATE packet_loss_events 
                    SET end_time = ?, duration_seconds = ?, is_active = 0
                    WHERE id = ?
                ''', (end_time, int(duration), self.current_loss_event['id']))
                
                conn.commit()
                conn.close()
                
                self.logger.info(f"Packet Loss Event beendet. Dauer: {duration:.1f}s, Failures: {self.current_loss_event['consecutive_failures']}")
            except Exception as e:
                self.logger.error(f"Fehler beim Beenden des Packet Loss Events: {e}")
            
            self.current_loss_event = None
    
    def monitor_loop(self):
        """Hauptschleife für das Ping-Monitoring"""
        
        while self.running:
            start_time = time.time()
            
            # Ping ausführen
            success, response_time = self.ping_host(self.current_host)
            
            # Statistiken aktualisieren
            self.total_pings += 1
            ping_result = {
                'timestamp': datetime.now().isoformat(),
                'host': self.current_host,
                'success': success,
                'response_time': response_time,
                'packet_loss': self.calculate_packet_loss()
            }
            
            if success:
                # Erfolgreicher Ping - beende aktuelles Packet Loss Event falls vorhanden
                if self.current_loss_event:
                    self.end_packet_loss_event()
                self.consecutive_failures = 0
                self.logger.info(f"Ping erfolgreich: {self.current_host} - {response_time}ms")
            else:
                # Fehlgeschlagener Ping
                self.failed_pings += 1
                self.consecutive_failures += 1
                
                # Packet Loss Event Management
                if self.current_loss_event:
                    self.update_packet_loss_event()
                else:
                    self.start_packet_loss_event()
                
                self.logger.warning(f"Ping fehlgeschlagen: {self.current_host} (Consecutive: {self.consecutive_failures})")
                
                # Nach X aufeinanderfolgenden Fehlern zum anderen Host wechseln
                if self.consecutive_failures >= self.failover_threshold:
                    self.switch_host()
                    # Beende aktuelles Event da wir den Host wechseln
                    if self.current_loss_event:
                        self.end_packet_loss_event()
                    self.consecutive_failures = 0
            
            # Ergebnis speichern
            self.recent_pings.append(ping_result)
            self.save_ping_result(self.current_host, success, response_time)
            
            # Regelmäßig Statistiken speichern
            if self.total_pings % Config.STATS_SAVE_INTERVAL == 0:
                self.save_statistics()
            
            # Warten bis zum nächsten Intervall
            elapsed = time.time() - start_time
            sleep_time = max(0, self.ping_interval - elapsed)
            time.sleep(sleep_time)
    
    def start(self):
        """Startet den Ping-Monitor"""
        self.running = True
        self.logger.info("Ping-Monitor gestartet")
        self.monitor_loop()
    
    def stop(self):
        """Stoppt den Ping-Monitor"""
        self.running = False
        self.save_statistics()
        self.logger.info("Ping-Monitor gestoppt")
    
    def signal_handler(self, signum, frame):
        """Signal handler für graceful shutdown"""
        self.logger.info(f"Signal {signum} empfangen, stoppe Monitor...")
        self.stop()
        sys.exit(0)
    
    def get_current_stats(self):
        """Gibt aktuelle Statistiken zurück"""
        # Berechne durchschnittliche Response Time der letzten erfolgreichen Pings
        recent_successful_pings = [p for p in self.recent_pings if p['success'] and p['response_time'] is not None]
        avg_response_time = 0
        if recent_successful_pings:
            avg_response_time = sum(p['response_time'] for p in recent_successful_pings) / len(recent_successful_pings)
        
        return {
            'total_pings': self.total_pings,
            'failed_pings': self.failed_pings,
            'packet_loss_percent': self.calculate_packet_loss(),
            'current_host': self.current_host,
            'avg_response_time': round(avg_response_time, 2),
            'recent_pings': list(self.recent_pings)[-100:],  # Letzte 100 Pings
            'uptime': datetime.now().isoformat()
        }

if __name__ == "__main__":
    monitor = PingMonitor()
    try:
        monitor.start()
    except KeyboardInterrupt:
        monitor.stop()
#!/usr/bin/env python3
"""
Web Interface für Ping Monitor
Flask-basierte Web-Oberfläche auf Port 4000
"""

from flask import Flask, render_template, jsonify, request
import sqlite3
import json
from datetime import datetime, timedelta
import threading
import os
from ping_monitor import PingMonitor
from config import Config

app = Flask(__name__)

# Globale Monitor-Instanz
monitor = None
monitor_thread = None

def get_db_connection():
    """Erstellt eine Datenbankverbindung"""
    conn = sqlite3.connect(Config.DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/')
def index():
    """Hauptseite"""
    return render_template('index.html')

@app.route('/api/stats')
def api_stats():
    """API-Endpunkt für aktuelle Statistiken"""
    if monitor:
        return jsonify(monitor.get_current_stats())
    else:
        return jsonify({'error': 'Monitor nicht aktiv'}), 500

@app.route('/api/history')
def api_history():
    """API-Endpunkt für historische Daten"""
    hours = request.args.get('hours', 24, type=int)
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Daten der letzten X Stunden abrufen
        since = datetime.now() - timedelta(hours=hours)
        cursor.execute('''
            SELECT timestamp, host, success, response_time, packet_loss_percent
            FROM ping_results
            WHERE timestamp > ?
            ORDER BY timestamp DESC
            LIMIT 1000
        ''', (since,))
        
        results = []
        for row in cursor.fetchall():
            results.append({
                'timestamp': row['timestamp'],
                'host': row['host'],
                'success': bool(row['success']),
                'response_time': row['response_time'],
                'packet_loss_percent': row['packet_loss_percent']
            })
        
        conn.close()
        return jsonify(results)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/summary')
def api_summary():
    """API-Endpunkt für Zusammenfassung"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Statistiken der letzten 24 Stunden
        since_24h = datetime.now() - timedelta(hours=24)
        cursor.execute('''
            SELECT 
                COUNT(*) as total_pings,
                SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failed_pings,
                AVG(response_time) as avg_response_time,
                MIN(response_time) as min_response_time,
                MAX(response_time) as max_response_time
            FROM ping_results
            WHERE timestamp > ? AND success = 1
        ''', (since_24h,))
        
        stats_24h = cursor.fetchone()
        
        # Aktuelle Packet Loss Rate
        cursor.execute('''
            SELECT packet_loss_percent
            FROM ping_results
            ORDER BY timestamp DESC
            LIMIT 1
        ''')
        
        current_loss = cursor.fetchone()
        
        conn.close()
        
        return jsonify({
            'last_24h': {
                'total_pings': stats_24h['total_pings'],
                'failed_pings': stats_24h['failed_pings'],
                'packet_loss_percent': (stats_24h['failed_pings'] / stats_24h['total_pings'] * 100) if stats_24h['total_pings'] > 0 else 0,
                'avg_response_time': round(stats_24h['avg_response_time'] or 0, 2),
                'min_response_time': stats_24h['min_response_time'],
                'max_response_time': stats_24h['max_response_time']
            },
            'current_packet_loss': current_loss['packet_loss_percent'] if current_loss else 0
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/control/<action>')
def api_control(action):
    """API-Endpunkt für Monitor-Kontrolle"""
    global monitor, monitor_thread
    
    if action == 'start':
        if not monitor or not monitor.running:
            monitor = PingMonitor()
            monitor_thread = threading.Thread(target=monitor.start)
            monitor_thread.daemon = True
            monitor_thread.start()
            return jsonify({'status': 'Monitor gestartet'})
        else:
            return jsonify({'status': 'Monitor läuft bereits'})
    
    elif action == 'stop':
        if monitor and monitor.running:
            monitor.stop()
            return jsonify({'status': 'Monitor gestoppt'})
        else:
            return jsonify({'status': 'Monitor läuft nicht'})
    
    elif action == 'status':
        if monitor and monitor.running:
            return jsonify({'status': 'running', 'stats': monitor.get_current_stats()})
        else:
            return jsonify({'status': 'stopped'})
    
    else:
        return jsonify({'error': 'Unbekannte Aktion'}), 400

def start_monitor_background():
    """Startet den Monitor im Hintergrund"""
    global monitor, monitor_thread
    monitor = PingMonitor()
    monitor_thread = threading.Thread(target=monitor.start)
    monitor_thread.daemon = True
    monitor_thread.start()

if __name__ == '__main__':
    # Konfiguration ausgeben
    Config.print_config()
    
    # Monitor automatisch starten
    start_monitor_background()
    
    # Flask-App starten
    app.run(host=Config.WEB_HOST, port=Config.WEB_PORT, debug=Config.DEBUG_MODE)
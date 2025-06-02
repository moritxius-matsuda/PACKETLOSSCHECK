#!/usr/bin/env python3
"""
Test-Skript für lokale Entwicklung
Startet den Ping Monitor ohne systemd-Service für Tests
"""

import os
import sys
import threading
import time
from ping_monitor import PingMonitor
from web_interface import app

def test_ping_monitor():
    """Testet den Ping Monitor"""
    print("🧪 Teste Ping Monitor...")
    
    monitor = PingMonitor("test_ping_data.db")
    
    # Kurzer Test - 10 Pings
    print("📡 Führe 10 Test-Pings aus...")
    for i in range(10):
        success, response_time = monitor.ping_host(monitor.primary_host)
        status = "✅ SUCCESS" if success else "❌ FAILED"
        time_str = f" ({response_time}ms)" if response_time else ""
        print(f"   Ping {i+1}: {status} - {monitor.primary_host}{time_str}")
        
        monitor.total_pings += 1
        if not success:
            monitor.failed_pings += 1
        
        time.sleep(0.5)
    
    # Statistiken anzeigen
    stats = monitor.get_current_stats()
    print(f"\n📊 Test-Statistiken:")
    print(f"   Gesamt Pings: {stats['total_pings']}")
    print(f"   Fehlgeschlagen: {stats['failed_pings']}")
    print(f"   Packet Loss: {stats['packet_loss_percent']:.2f}%")
    
    return monitor

def start_test_server():
    """Startet den Test-Server"""
    print("🌐 Starte Test-Web-Server auf http://localhost:4000")
    print("   Drücke Ctrl+C zum Beenden")
    
    # Monitor im Hintergrund starten
    monitor = PingMonitor("test_ping_data.db")
    monitor_thread = threading.Thread(target=monitor.start)
    monitor_thread.daemon = True
    monitor_thread.start()
    
    # Flask-App starten
    try:
        app.run(host='127.0.0.1', port=4000, debug=True)
    except KeyboardInterrupt:
        print("\n🛑 Server gestoppt")
        monitor.stop()

def cleanup_test_files():
    """Entfernt Test-Dateien"""
    test_files = ["test_ping_data.db", "ping_monitor.log"]
    for file in test_files:
        if os.path.exists(file):
            os.remove(file)
            print(f"🗑️ Entfernt: {file}")

def main():
    """Hauptfunktion"""
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "test":
            test_ping_monitor()
        elif command == "server":
            start_test_server()
        elif command == "cleanup":
            cleanup_test_files()
        else:
            print("❌ Unbekannter Befehl")
            print_usage()
    else:
        print_usage()

def print_usage():
    """Zeigt Verwendungshinweise"""
    print("🧪 Ping Monitor Test-Skript")
    print("")
    print("Verwendung:")
    print("   python3 test_local.py test     - Führt Ping-Tests aus")
    print("   python3 test_local.py server   - Startet Test-Server")
    print("   python3 test_local.py cleanup  - Entfernt Test-Dateien")
    print("")
    print("Beispiele:")
    print("   python3 test_local.py test")
    print("   python3 test_local.py server")

if __name__ == "__main__":
    main()
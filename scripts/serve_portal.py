#!/usr/bin/env python3
"""
NotchDeck Wireless Android APK Download Portal
Serves the latest Android APK over your local Wi-Fi gateway (e.g. http://192.168.1.3:8080).
"""

import os
import sys
import socket
import datetime
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
PORTAL_HTML_PATH = os.path.join(SCRIPT_DIR, "portal", "index.html")
APK_PATH = os.path.join(ROOT_DIR, "android", "app", "build", "outputs", "apk", "debug", "app-debug.apk")
PORT = 8080

def get_local_ip():
    """Detect local Wi-Fi/LAN IPv4 address."""
    # Try macOS ipconfig getifaddr en0 (standard Wi-Fi interface)
    for iface in ["en0", "en1"]:
        try:
            ip = subprocess.check_output(["ipconfig", "getifaddr", iface], stderr=subprocess.DEVNULL).decode().strip()
            if ip and not ip.startswith("127."):
                return ip
        except Exception:
            pass

    # Fallback to UDP socket trick
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def format_size(bytes_size):
    """Format file size in human-readable units."""
    if bytes_size >= 1024 * 1024:
        return f"{bytes_size / (1024 * 1024):.1f} MB"
    elif bytes_size >= 1024:
        return f"{bytes_size / 1024:.1f} KB"
    return f"{bytes_size} B"

class PortalRequestHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Clean logging
        sys.stdout.write(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] {args[0]} - {args[1]} - {args[2]}\n")

    def do_HEAD(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path in ["/NotchDeck.apk", "/MacDeck.apk", "/app-debug.apk", "/download", "/apk"]:
            if os.path.exists(APK_PATH):
                size = os.path.getsize(APK_PATH)
                self.send_response(200)
                self.send_header("Content-Type", "application/vnd.android.package-archive")
                self.send_header("Content-Disposition", 'attachment; filename="NotchDeck.apk"')
                self.send_header("Content-Length", str(size))
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
            else:
                self.send_error(404, "APK Not Found")
        elif path in ["/", "/index.html"]:
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
        else:
            self.send_error(404, "Not Found")

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path in ["/", "/index.html"]:
            self.serve_portal()
        elif path in ["/NotchDeck.apk", "/MacDeck.apk", "/app-debug.apk", "/download", "/apk"]:
            self.serve_apk()
        elif path == "/api/status":
            self.serve_status()
        else:
            self.send_error(404, "File Not Found")

    def serve_portal(self):
        if not os.path.exists(PORTAL_HTML_PATH):
            self.send_error(500, "Portal template missing")
            return

        with open(PORTAL_HTML_PATH, "r", encoding="utf-8") as f:
            template = f.read()

        local_ip = get_local_ip()
        apk_size = "16.5 MB"
        build_date = "Recently"

        if os.path.exists(APK_PATH):
            size_b = os.path.getsize(APK_PATH)
            apk_size = format_size(size_b)
            mtime = os.path.getmtime(APK_PATH)
            build_date = datetime.datetime.fromtimestamp(mtime).strftime("%b %d, %H:%M")

        html = template.replace("{{MAC_IP}}", local_ip)
        html = html.replace("{{PORT}}", str(PORT))
        html = html.replace("{{APK_SIZE}}", apk_size)
        html = html.replace("{{BUILD_DATE}}", build_date)

        body = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.end_headers()
        self.wfile.write(body)

    def serve_apk(self):
        if not os.path.exists(APK_PATH):
            self.send_error(404, "APK not found. Please build the Android app first.")
            return

        size = os.path.getsize(APK_PATH)
        self.send_response(200)
        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Content-Disposition", 'attachment; filename="NotchDeck.apk"')
        self.send_header("Content-Length", str(size))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()

        with open(APK_PATH, "rb") as f:
            chunk_size = 64 * 1024
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                try:
                    self.wfile.write(chunk)
                except BrokenPipeError:
                    break

    def serve_status(self):
        local_ip = get_local_ip()
        json_data = f'{{"status":"ok","macIp":"{local_ip}","wsPort":8765,"portalPort":{PORT}}}'
        body = json_data.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

def main():
    local_ip = get_local_ip()
    portal_url = f"http://{local_ip}:{PORT}"
    apk_url = f"http://{local_ip}:{PORT}/NotchDeck.apk"

    print("=" * 64)
    print("  📲 NotchDeck Wireless Android Download Portal")
    print("=" * 64)
    print()
    print(f"  🌐 Portal Web URL:   \033[1;36m{portal_url}\033[0m")
    print(f"  📦 Direct APK Link:  \033[1;32m{apk_url}\033[0m")
    print(f"  💻 Mac Host Server:  \033[1;33m{local_ip}:8765\033[0m")
    print()

    # Try printing terminal ASCII QR code
    try:
        import qrcode
        qr = qrcode.QRCode(border=2)
        qr.add_data(portal_url)
        print("  📷 Scan this QR code with your Android Camera:")
        print()
        qr.print_ascii(invert=True)
        print()
    except Exception:
        pass

    print("=" * 64)
    print(f"  👉 Open Chrome on your Android phone and visit: {portal_url}")
    print("  Tap 'Download NotchDeck APK' -> Open -> Install.")
    print("  Press Ctrl+C to stop server.")
    print("=" * 64)
    print()

    server = HTTPServer(("0.0.0.0", PORT), PortalRequestHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n⏹️ Portal server stopped.")

if __name__ == "__main__":
    main()

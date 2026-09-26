#!/usr/bin/env python3
"""
NotchDeck Wireless Android APK Download Portal
Dynamically adapts IP address based on connected interface (Wi-Fi, Hotspot, USB Tethering, LAN).
Serves the latest Android APK over your active network gateway.
"""

import os
import sys
import socket
import datetime
import subprocess
import json
import urllib.parse
try:
    from http.server import ThreadingHTTPServer as ServerClass, BaseHTTPRequestHandler
except ImportError:
    from http.server import HTTPServer as ServerClass, BaseHTTPRequestHandler

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)

def resolve_portal_html():
    candidates = [
        os.path.join(SCRIPT_DIR, "portal", "index.html"),
        os.path.join(SCRIPT_DIR, "index.html"),
        os.path.join(ROOT_DIR, "scripts", "portal", "index.html"),
        os.path.join(ROOT_DIR, "portal", "index.html"),
        os.path.join(ROOT_DIR, "Resources", "portal", "index.html"),
        os.path.join(ROOT_DIR, "Resources", "index.html"),
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return candidates[0]

def resolve_apk_path():
    env_path = os.environ.get("NOTCHDECK_APK_PATH")
    if env_path and os.path.exists(env_path):
        return env_path
    candidates = [
        os.path.join(SCRIPT_DIR, "NotchDeck.apk"),
        os.path.join(SCRIPT_DIR, "app-debug.apk"),
        os.path.join(ROOT_DIR, "Resources", "NotchDeck.apk"),
        os.path.join(ROOT_DIR, "Resources", "app-debug.apk"),
        os.path.join(ROOT_DIR, "android", "app", "build", "outputs", "apk", "debug", "app-debug.apk"),
        os.path.join(ROOT_DIR, "android", "app", "build", "outputs", "apk", "release", "app-release.apk"),
        os.path.expanduser("~/.notchdeck/NotchDeck.apk"),
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return candidates[0]

PORTAL_HTML_PATH = resolve_portal_html()
APK_PATH = resolve_apk_path()
PORT = 8080

def detect_primary_ip():
    """Detect default outgoing LAN IP using kernel route lookup without sending traffic."""
    for target in [("1.1.1.1", 53), ("8.8.8.8", 53), ("192.168.1.1", 53), ("10.0.0.1", 53)]:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.settimeout(0.4)
            s.connect(target)
            ip = s.getsockname()[0]
            s.close()
            if ip and not ip.startswith("127.") and not ip.startswith("169.254."):
                return ip
        except Exception:
            pass
    return None

def get_all_local_interfaces():
    """
    Scans all network interfaces and extracts valid, active IPv4 addresses.
    Supports Wi-Fi, Ethernet, Hotspot, USB Tethering (bridge100, rndis, etc.).
    Returns list of dicts: [{'name': 'en0', 'ip': '...', 'type': '...', 'isPrimary': bool}]
    """
    primary_ip = detect_primary_ip()
    interfaces = []
    seen_ips = set()

    # Try ifconfig parsing on macOS / Linux
    try:
        out = subprocess.check_output(["ifconfig"], stderr=subprocess.DEVNULL, text=True)
        current_iface = None
        current_flags = ""
        current_status = ""

        for line in out.splitlines():
            if line and not line.startswith("\t") and not line.startswith(" "):
                current_iface = line.split(":")[0]
                current_flags = line
                current_status = ""
            elif current_iface:
                line_s = line.strip()
                if line_s.startswith("status:"):
                    current_status = line_s.split(":", 1)[1].strip().lower()
                elif line_s.startswith("inet "):
                    parts = line_s.split()
                    if len(parts) >= 2:
                        ip = parts[1]
                        if not ip.startswith("127.") and not ip.startswith("169.254.") and ip != "0.0.0.0":
                            is_up = "UP" in current_flags and "RUNNING" in current_flags and "LOOPBACK" not in current_flags
                            if is_up and current_status != "inactive":
                                if ip not in seen_ips:
                                    seen_ips.add(ip)
                                    if current_iface == "en0":
                                        iface_type = "Wi-Fi"
                                    elif current_iface.startswith("bridge") or current_iface.startswith("rndis"):
                                        iface_type = "USB / Hotspot Bridge"
                                    elif current_iface.startswith("ap") or current_iface.startswith("pdp_ip"):
                                        iface_type = "Personal Hotspot"
                                    elif current_iface.startswith("en"):
                                        iface_type = "Ethernet / LAN"
                                    else:
                                        iface_type = "LAN Interface"

                                    is_primary = (primary_ip == ip)
                                    interfaces.append({
                                        "name": current_iface,
                                        "ip": ip,
                                        "type": iface_type,
                                        "isPrimary": is_primary
                                    })
    except Exception:
        pass

    # Also query macOS ipconfig for common interfaces if ifconfig missed anything
    for iface in ["en0", "en1", "en2", "en3", "en4", "en5", "en6", "bridge100", "bridge0", "ap1"]:
        try:
            ip = subprocess.check_output(["ipconfig", "getifaddr", iface], stderr=subprocess.DEVNULL, text=True).strip()
            if ip and not ip.startswith("127.") and not ip.startswith("169.254.") and ip not in seen_ips:
                seen_ips.add(ip)
                iface_type = "Wi-Fi" if iface == "en0" else ("USB / Bridge" if iface.startswith("bridge") else "LAN")
                interfaces.append({
                    "name": iface,
                    "ip": ip,
                    "type": iface_type,
                    "isPrimary": (primary_ip == ip)
                })
        except Exception:
            pass

    # If primary_ip was found but somehow not in interfaces list, add it
    if primary_ip and primary_ip not in seen_ips:
        interfaces.append({
            "name": "default",
            "ip": primary_ip,
            "type": "Active Route",
            "isPrimary": True
        })
        seen_ips.add(primary_ip)

    # Sort interfaces: Primary first, then Wi-Fi, then others
    interfaces.sort(key=lambda x: (not x.get("isPrimary", False), x.get("name", "") != "en0", x.get("name", "")))
    return interfaces

def get_best_local_ip():
    """Returns the primary active LAN IP or fallback."""
    interfaces = get_all_local_interfaces()
    if interfaces:
        return interfaces[0]["ip"]
    primary = detect_primary_ip()
    if primary:
        return primary
    return "127.0.0.1"

def format_size(bytes_size):
    """Format file size in human-readable units."""
    if bytes_size >= 1024 * 1024:
        return f"{bytes_size / (1024 * 1024):.1f} MB"
    elif bytes_size >= 1024:
        return f"{bytes_size / 1024:.1f} KB"
    return f"{bytes_size} B"

def parse_range_header(range_header, file_size):
    """
    Parses HTTP Range header like 'bytes=0-1023', 'bytes=1024-', or 'bytes=-500'.
    Returns (start, end) tuple or None.
    """
    if not range_header or not range_header.startswith("bytes="):
        return None
    try:
        ranges = range_header[6:].split(",")[0].strip()
        if "-" not in ranges:
            return None
        parts = ranges.split("-", 1)
        start_str, end_str = parts[0].strip(), parts[1].strip()

        if not start_str and not end_str:
            return None

        if not start_str:
            suffix = int(end_str)
            if suffix <= 0:
                return None
            start = max(0, file_size - suffix)
            end = file_size - 1
        elif not end_str:
            start = int(start_str)
            if start >= file_size:
                return None
            end = file_size - 1
        else:
            start = int(start_str)
            end = int(end_str)
            if start > end or start >= file_size:
                return None
            end = min(end, file_size - 1)

        return (start, end)
    except Exception:
        return None

class PortalRequestHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def handle_one_request(self):
        try:
            super().handle_one_request()
        except (ConnectionResetError, BrokenPipeError, socket.timeout):
            self.close_connection = True

    def log_message(self, format, *args):
        # Ignore noisy /api/status health checks from local background pollers
        if args and len(args) > 0 and "/api/status" in str(args[0]):
            return
        sys.stdout.write(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] {args[0]} - {args[1]} - {args[2]}\n")

    def get_effective_host_ip(self):
        """
        Dynamically adapts IP address based on how the device reached this portal.
        Priority:
        1. HTTP 'Host' header sent by client (e.g. 192.168.43.15, 10.0.0.4, 127.0.0.1)
        2. Local socket interface address that accepted this specific TCP connection
        3. Primary detected LAN IP
        """
        host_hdr = self.headers.get("Host", "")
        if host_hdr:
            clean_host = host_hdr.split(":")[0].strip("[]")
            if clean_host and clean_host != "localhost" and clean_host != "0.0.0.0":
                return clean_host

        try:
            sock_ip = self.connection.getsockname()[0]
            if sock_ip and not sock_ip.startswith("0.0.0.0"):
                return sock_ip
        except Exception:
            pass

        return get_best_local_ip()

    timeout = 60

    def do_HEAD(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path.lower().endswith(".apk") or path in ["/download", "/apk"]:
            self.serve_apk(is_head=True)
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
        elif path.lower().endswith(".apk") or path in ["/download", "/apk"]:
            self.serve_apk()
        elif path == "/api/status":
            self.serve_status()
        elif path == "/api/interfaces":
            self.serve_interfaces()
        elif path in ["/api/qr", "/qr.svg", "/qr"]:
            self.serve_qr(parsed.query)
        else:
            self.send_error(404, "File Not Found")

    def serve_portal(self):
        html_path = resolve_portal_html()
        if not os.path.exists(html_path):
            self.send_error(500, "Portal template missing")
            return

        with open(html_path, "r", encoding="utf-8") as f:
            template = f.read()

        effective_ip = self.get_effective_host_ip()
        all_interfaces = get_all_local_interfaces()
        apk_size = "16.5 MB"
        build_date = "Recently"

        apk_path = resolve_apk_path()
        if os.path.exists(apk_path):
            size_b = os.path.getsize(apk_path)
            apk_size = format_size(size_b)
            mtime = os.path.getmtime(apk_path)
            build_date = datetime.datetime.fromtimestamp(mtime).strftime("%b %d, %H:%M")

        html = template.replace("{{MAC_IP}}", effective_ip)
        html = html.replace("{{PORT}}", str(PORT))
        html = html.replace("{{APK_SIZE}}", apk_size)
        html = html.replace("{{BUILD_DATE}}", build_date)
        html = html.replace("{{INTERFACES_JSON}}", json.dumps(all_interfaces))

        body = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.end_headers()
        self.wfile.write(body)

    def serve_apk(self, is_head=False):
        apk_path = resolve_apk_path()
        if not os.path.exists(apk_path):
            self.send_error(404, "APK not found. Please build the Android app first.")
            return

        file_size = os.path.getsize(apk_path)
        mtime = os.path.getmtime(apk_path)
        etag = f'"{int(mtime)}-{file_size}"'
        last_modified = datetime.datetime.fromtimestamp(mtime, datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S GMT")

        range_header = self.headers.get("Range")
        range_bounds = parse_range_header(range_header, file_size)

        if range_bounds:
            start, end = range_bounds
            content_length = end - start + 1
            self.send_response(206, "Partial Content")
            self.send_header("Content-Range", f"bytes {start}-{end}/{file_size}")
            self.send_header("Content-Length", str(content_length))
        else:
            start = 0
            end = file_size - 1
            content_length = file_size
            self.send_response(200, "OK")
            self.send_header("Content-Length", str(file_size))

        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Content-Disposition", 'attachment; filename="NotchDeck.apk"')
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("ETag", etag)
        self.send_header("Last-Modified", last_modified)
        self.send_header("Cache-Control", "no-cache, no-transform")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        if is_head:
            return

        with open(apk_path, "rb") as f:
            f.seek(start)
            bytes_left = content_length
            chunk_size = 64 * 1024
            while bytes_left > 0:
                read_amount = min(chunk_size, bytes_left)
                chunk = f.read(read_amount)
                if not chunk:
                    break
                try:
                    self.wfile.write(chunk)
                    bytes_left -= len(chunk)
                except (BrokenPipeError, ConnectionResetError):
                    break

    def serve_status(self):
        effective_ip = self.get_effective_host_ip()
        interfaces = get_all_local_interfaces()
        status_data = {
            "status": "ok",
            "macIp": effective_ip,
            "primaryIp": get_best_local_ip(),
            "allInterfaces": interfaces,
            "wsPort": 8765,
            "portalPort": PORT
        }
        body = json.dumps(status_data).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def serve_interfaces(self):
        interfaces = get_all_local_interfaces()
        body = json.dumps(interfaces).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def serve_qr(self, query_string):
        params = urllib.parse.parse_qs(query_string)
        effective_ip = self.get_effective_host_ip()
        default_url = f"http://{effective_ip}:{PORT}/NotchDeck.apk"
        target_url = params.get("data", [default_url])[0]

        try:
            import qrcode
            import qrcode.image.svg
            import io

            factory = qrcode.image.svg.SvgPathImage
            img = qrcode.make(target_url, image_factory=factory)
            buf = io.BytesIO()
            img.save(buf)
            body = buf.getvalue()

            self.send_response(200)
            self.send_header("Content-Type", "image/svg+xml")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            self.send_error(500, f"QR Generation Error: {e}")

def main():
    interfaces = get_all_local_interfaces()
    primary_ip = get_best_local_ip()

    print("=" * 68)
    print("  📲 NotchDeck Wireless Android Download Portal")
    print("  🔄 Dynamic IP Adaptation Enabled (Adapts to Active Interface)")
    print("=" * 68)
    print()
    if interfaces:
        print("  🌐 Available Connection Interfaces:")
        for iface in interfaces:
            mark = "★ (Primary)" if iface.get("isPrimary") else " "
            name = iface.get("name", "")
            itype = iface.get("type", "LAN")
            ip = iface.get("ip", "")
            print(f"     👉 [{itype} - {name}] http://{ip}:{PORT}  {mark}")
            print(f"        Direct APK: http://{ip}:{PORT}/NotchDeck.apk")
    else:
        print(f"  👉 Portal Web URL:   http://{primary_ip}:{PORT}")
        print(f"  👉 Direct APK Link:  http://{primary_ip}:{PORT}/NotchDeck.apk")

    print()
    print("  🔌 USB Mode (Localhost / ADB Reverse):")
    print(f"     Direct APK: http://127.0.0.1:{PORT}/NotchDeck.apk")
    print("     (Run: ./scripts/usb/connect.sh)")
    print("=" * 68)
    print(f"  👉 Open Chrome on your Android phone and visit the link above.")
    print("  Tap 'Download NotchDeck APK' -> Open -> Install.")
    print("  Press Ctrl+C to stop server.")
    print("=" * 68)
    print()

    # Try printing terminal ASCII QR code for primary IP
    primary_url = f"http://{primary_ip}:{PORT}/?auto=1"
    try:
        import qrcode
        qr = qrcode.QRCode(border=2)
        qr.add_data(primary_url)
        print("  📷 Scan this QR code with your Android Camera:")
        print()
        qr.print_ascii(invert=True)
        print()
    except Exception:
        pass

    # Bind server with SO_REUSEADDR and graceful stale port cleanup
    ServerClass.allow_reuse_address = True
    try:
        server = ServerClass(("0.0.0.0", PORT), PortalRequestHandler)
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"⚠️ Port {PORT} is occupied by an existing process. Terminating stale server...")
            try:
                out = subprocess.check_output(["lsof", "-ti", f":{PORT}"], text=True).strip()
                for p in out.splitlines():
                    p = p.strip()
                    if p and p != str(os.getpid()):
                        subprocess.run(["kill", "-9", p])
                import time
                time.sleep(0.5)
                server = ServerClass(("0.0.0.0", PORT), PortalRequestHandler)
            except Exception as kill_err:
                print(f"❌ Failed to free port {PORT}: {kill_err}")
                sys.exit(1)
        else:
            raise

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n⏹️ Portal server stopped.")

if __name__ == "__main__":
    main()

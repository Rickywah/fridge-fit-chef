"""Local static server for web/ + config/; optional ngrok tunnel."""
import http.server
import os
import socket
import sys
import threading

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, "web")
PORT = 8765


class AppHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB, **kwargs)

    def translate_path(self, path):
        if path.startswith("/config/") or path == "/config/config.js":
            rel = path.lstrip("/")
            return os.path.join(ROOT, rel.replace("/", os.sep))
        return super().translate_path(path)


def find_free_port(start=8765):
    for p in range(start, start + 20):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("127.0.0.1", p)) != 0:
                return p
    return start


def main():
    port = find_free_port(PORT)
    httpd = http.server.HTTPServer(("127.0.0.1", port), AppHandler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    local = f"http://127.0.0.1:{port}/fridge-fit-chef.html"
    print(f"Local: {local}")

    try:
        import ngrok
        listener = ngrok.forward(f"http://127.0.0.1:{port}", authtoken_from_env=True)
        share = listener.url().rstrip("/") + "/fridge-fit-chef.html"
        print("\n=== SHARE THIS URL ===")
        print(share)
    except Exception as e:
        print(f"\nTunnel skipped: {e}")
        print("Open the local URL above on same WiFi, or run scripts\\make-share-pack.ps1")

    print("\nPress Ctrl+C to stop.")
    try:
        while True:
            threading.Event().wait(3600)
    except KeyboardInterrupt:
        pass
    finally:
        httpd.shutdown()


if __name__ == "__main__":
    main()

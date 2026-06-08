#!/usr/bin/env python3
"""Tiny static server for the Godot Web export (correct .wasm MIME, no cache).
Usage: python3 serve.py [port]   (default 8088)  ->  http://127.0.0.1:<port>
GL Compatibility + no-threads export needs no special COOP/COEP headers."""
import http.server, socketserver, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8088

class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
        ".js": "text/javascript", ".mjs": "text/javascript",
        ".wasm": "application/wasm", ".json": "application/json",
        ".pck": "application/octet-stream"}
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
    print(f"serving on http://127.0.0.1:{PORT}")
    httpd.serve_forever()

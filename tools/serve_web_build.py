#!/usr/bin/env python3
"""Serves build/web with the two headers a threaded Godot web export cannot start without.

A plain `python3 -m http.server` looks like it works and then the game never boots: the export
is built with thread support, which needs SharedArrayBuffer, which browsers only expose to a
cross-origin-isolated page. Without COOP/COEP the failure surfaces inside the engine's own
startup as an unrelated-looking error, so this exists to stop anyone debugging the game when
the problem is the web server.

    python3 tools/serve_web_build.py [port]
"""
import functools, http.server, os, socketserver, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8099
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, fmt, *args):
        sys.stderr.write("%s\n" % (fmt % args))


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", PORT),
                            functools.partial(Handler, directory=ROOT)) as httpd:
    print("serving %s at http://127.0.0.1:%d/index.html" % (ROOT, PORT), flush=True)
    httpd.serve_forever()

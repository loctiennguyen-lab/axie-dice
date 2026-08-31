import http.server, socketserver, os
os.chdir('/home/claude/axie-dice/serve_root')
socketserver.TCPServer.allow_reuse_address=True
with socketserver.TCPServer(("",5173), http.server.SimpleHTTPRequestHandler) as h: h.serve_forever()

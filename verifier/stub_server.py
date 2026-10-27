import hmac, hashlib, json, sys, time
from http.server import BaseHTTPRequestHandler, HTTPServer

KEY = open(sys.argv[1], "rb").read().strip()
sample = json.load(open(sys.argv[2]))
h = sample["header"]
hl = h.get("loadout", {})


def payload(mismatch):
    # schema 1, see verifier/JOB_SCHEMA.md
    return {"schema": 1,
            "server_header": {"rules_version": h["rules_version"], "kind": "ranked" if h["ranked"] else "normal", "mode": h["mode"],
                              "ascension": h["ascension"], "ranked": h["ranked"], "depth_stage": h.get("depth_stage", 3),
                              "newcomer": False, "mission": None, "header_mismatch": mismatch},
            "server_loadout": {"bonuses": hl.get("bonuses", {}), "forced": {}, "server_unknown": ["anchor", "rules_on", "core_off", "boon_id"]},
            "client_header": {"team_keys": h["team_keys"], "content_version": h["content_version"], "local_secret": h.get("local_secret", 0),
                              "loadout": {"anchor": False, "rules_on": True, "core_off": False, "boon_id": ""}},
            "client_claim": {"outcome": "lost", "score": 1}, "entries": sample["entries"], "tape": sample["tape"]}


jobs = [("a" * 32, payload(False)), ("b" * 32, payload(True))]
results = {}


class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        ts = self.headers.get("X-Verify-Ts", "")
        sig = self.headers.get("X-Verify-Sig", "")
        msg = ("%s\nPOST\n%s\n" % (ts, self.path)).encode() + body
        want = hmac.new(KEY, msg, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(sig, want) or abs(time.time() - int(ts)) > 120:
            self.send(401, {"error": "unauthorized"}); return
        if self.path == "/api/verify/next":
            if jobs:
                rid, p = jobs.pop(0)
                self.send(200, {"job": {"run_id": rid, "rules_version": h["rules_version"], "payload": p}})
            else:
                self.send(200, {"job": None})
        else:
            m = json.loads(body)
            results[m["run_id"]] = m["result"]
            json.dump(results, open(sys.argv[3], "w"))
            self.send(200, {"ok": True})

    def send(self, code, obj):
        b = json.dumps(obj).encode()
        self.send_response(code); self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)


HTTPServer(("127.0.0.1", int(sys.argv[4])), H).serve_forever()

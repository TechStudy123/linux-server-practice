#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""社内のお知らせサイトの小さなアプリ（練習用）。
GET /api/notices → お知らせの一覧（JSON）。GET /api/health → {"status": "ok"}。
Python の標準ライブラリだけで動きます。127.0.0.1（サーバー自身）の 8080 番で待ち受けます。
お知らせのデータは、環境変数 NOTICE_DATA のファイル（JSON）から読みます。"""
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST = "127.0.0.1"
PORT = 8080
DATA = os.environ.get("NOTICE_DATA", "/srv/notice/data/notices.json")


class Handler(BaseHTTPRequestHandler):
    def send_json(self, code, body):
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/api/health":
            self.send_json(200, {"status": "ok"})
        elif self.path == "/api/notices":
            try:
                with open(DATA, encoding="utf-8") as f:
                    self.send_json(200, json.load(f))
            except OSError as e:
                print(f"データを読めません: {DATA}: {e.strerror}", flush=True)
                self.send_json(500, {"error": "data not available"})
        else:
            self.send_json(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"notice app: http://{HOST}:{PORT}/api/notices で待ち受けます（データ {DATA}）", flush=True)
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()

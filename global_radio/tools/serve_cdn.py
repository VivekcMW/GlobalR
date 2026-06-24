#!/usr/bin/env python3
"""Local static server that emulates the Cloudflare R2 / CDN origin.

Serves cdn_dist/ with CORS + byte-range support (just_audio streams via Range
requests) and correct audio/mpeg content-type, so the Flutter app can run the
REAL streaming path with DEMO_AUDIO=false against http://localhost:PORT.

    python tools/serve_cdn.py --dir cdn_dist --port 8787

Then:
    flutter run \
      --dart-define=DEMO_AUDIO=false \
      --dart-define=CDN_BASE=http://localhost:8787 \
      --dart-define=CATALOG_URL=http://localhost:8787/catalog.json
(use your machine's LAN IP instead of localhost for a physical device).
"""
from __future__ import annotations

import argparse
import os
import re
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

_RANGE_RE = re.compile(r"bytes=(\d*)-(\d*)")


class CDNHandler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map,
                      ".mp3": "audio/mpeg", ".json": "application/json"}

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Range")
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Cache-Control", "public, max-age=3600")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_GET(self):  # noqa: N802
        rng = self.headers.get("Range")
        path = self.translate_path(self.path)
        if not rng or not os.path.isfile(path):
            return super().do_GET()  # full file / dir listing / 404

        size = os.path.getsize(path)
        m = _RANGE_RE.match(rng)
        if not m:
            return super().do_GET()
        start = int(m.group(1)) if m.group(1) else 0
        end = int(m.group(2)) if m.group(2) else size - 1
        end = min(end, size - 1)
        if start > end:
            self.send_response(416)
            self.send_header("Content-Range", f"bytes */{size}")
            self.end_headers()
            return
        length = end - start + 1
        ctype = self.guess_type(path)
        self.send_response(206)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.send_header("Content-Length", str(length))
        self.end_headers()
        with open(path, "rb") as f:
            f.seek(start)
            self.wfile.write(f.read(length))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default="cdn_dist")
    ap.add_argument("--port", type=int, default=8787)
    args = ap.parse_args()
    handler = partial(CDNHandler, directory=args.dir)
    httpd = ThreadingHTTPServer(("0.0.0.0", args.port), handler)
    print(f"Serving {args.dir}/ at http://localhost:{args.port}  "
          f"(catalog: http://localhost:{args.port}/catalog.json)")
    httpd.serve_forever()


if __name__ == "__main__":
    main()

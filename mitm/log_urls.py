"""
mitmproxy addon: Xperia Companion isteklerini sade biçimde loglar.
- her istek: method + tam URL  -> urls.txt
- her yanit: status, content-type, content-length + firmware/CDN ipuclari -> responses.txt
Buyuk indirmeler (firmware .zip/.sin, Range) ayrica flagged.txt'e yazilir.
"""
from mitmproxy import http
import os

HERE = os.path.dirname(os.path.abspath(__file__))
URLS = os.path.join(HERE, "urls.txt")
RESP = os.path.join(HERE, "responses.txt")
FLAG = os.path.join(HERE, "flagged.txt")

def _append(path, line):
    with open(path, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def request(flow: http.HTTPFlow):
    r = flow.request
    rng = r.headers.get("range", "")
    line = f"{r.method} {r.pretty_url}"
    if rng:
        line += f"   [Range: {rng}]"
    _append(URLS, line)
    # host bazli ilgi: sony update/dagitim + olasi CDN
    host = r.pretty_host.lower()
    if any(k in host for k in ("swup", "update.sony", "sony.net", "cdn", "akamai", "cloudfront", "download", "dl.")):
        _append(FLAG, f"REQ {r.method} {r.pretty_url}" + (f"  [Range {rng}]" if rng else ""))

def response(flow: http.HTTPFlow):
    r = flow.request
    rsp = flow.response
    ct = rsp.headers.get("content-type", "")
    cl = rsp.headers.get("content-length", "")
    clv = int(cl) if cl.isdigit() else -1
    _append(RESP, f"{rsp.status_code} {ct} len={cl}  <-  {r.method} {r.pretty_url}")
    # buyuk binary indirme = firmware/CDN
    is_big = clv > 5_000_000
    is_fw = any(k in ct for k in ("zip", "octet-stream", "binary")) or r.pretty_url.lower().endswith((".zip", ".sin", ".ftf"))
    if is_big or (is_fw and clv > 100_000):
        _append(FLAG, f"RESP {rsp.status_code} {ct} len={cl}  <-  {r.pretty_url}")

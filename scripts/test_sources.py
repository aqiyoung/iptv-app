#!/usr/bin/env python3
"""批量测试 CCTV 源的 m3u8 可达性"""

import json
import urllib.request
import urllib.error
import time
import sys

DATA_FILE = "assets/data/cctv_sources.json"
TIMEOUT = 8

def test_url(url: str) -> tuple[bool, str]:
    """测试 URL 是否可达，返回 (ok, detail)"""
    try:
        req = urllib.request.Request(url, method="GET")
        req.add_header("User-Agent", "Mozilla/5.0")
        resp = urllib.request.urlopen(req, timeout=TIMEOUT)
        body = resp.read(1024).decode("utf-8", errors="ignore")
        if "#EXTM3U" in body:
            return True, f"OK ({resp.status})"
        elif resp.status == 200:
            return True, f"200 but no EXTM3U (first 100 chars: {body[:100]})"
        return False, f"status={resp.status}"
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}"
    except Exception as e:
        return False, f"{type(e).__name__}: {e}"

def main():
    with open(DATA_FILE) as f:
        data = json.load(f)

    channels = data.get("channels", {})
    total = 0
    alive = 0
    dead = 0

    print(f"测试 {len(channels)} 个频道的所有源 (timeout={TIMEOUT}s)...\n")

    for ch_id in sorted(channels.keys()):
        sources = channels[ch_id]
        ch_alive = 0
        ch_dead = 0
        results = []

        for src in sources:
            url = src["url"]
            ok, detail = test_url(url)
            total += 1
            status = "✅" if ok else "❌"
            if ok:
                alive += 1
                ch_alive += 1
            else:
                dead += 1
                ch_dead += 1
            results.append(f"  {status} {url.split('/')[-1]:30s} → {detail}")

        print(f"📺 {ch_id}: {ch_alive}/{len(sources)} 存活")
        for r in results:
            print(r)
        print()

    print(f"\n{'='*60}")
    print(f"总计: {total} 个源, {alive} 存活, {dead} 死亡")
    print(f"存活率: {alive/total*100:.1f}%")

if __name__ == "__main__":
    main()

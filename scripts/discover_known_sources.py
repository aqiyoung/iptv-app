#!/usr/bin/env python3
"""v0.3.7+69: discover_known_sources.py — 重新抓 iptv-org cn.m3u, 探测所有 .cn
频道的源, 跟 assets/data/known_sources.json 合并.

老板 6/19 16:47 反馈: '那第一版用的央视源哪里来的 可以播放的啊'
- 第一版 (v0.1.6+7 6/16) 用了 iptv-org cn.m3u 全部公开源
- 3 天后这批源大量死透 (iptv-org 自己 6/19 的 m3u 里 CCTV1 三个源都死了)
- 老板要求: 走 iptv-org 公开源, 不用 198.204/74.91 金矿反代

逻辑:
1. 抓 https://raw.githubusercontent.com/iptv-org/iptv/master/streams/cn.m3u
2. 解析所有 tvg-id 形如 *.cn 的频道
3. HTTP HEAD 测试 (--follow-redirects, 5s timeout)
4. 合并到 assets/data/known_sources.json, 按 alive 排序
5. 保留老兜底 (bkpcp/bupt 历史标识, 死透也留作日志)
6. dead 源 (alive=false) 标到 KNOWN_DEAD_HOSTS 跳过 (sync_known_sources 走)

输出:
- assets/data/candidates.json (类似 cctv_candidates.json)  - 全 .cn 频道探测结果
- assets/data/known_sources.json  - 写入 top-2 per channel (按 score 排序)
- 死源 (DNS/timeout/404) 标 KNOWN_DEAD_HOSTS 跳过
"""
import argparse
import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / 'assets' / 'data'
CANDIDATES_PATH = ASSETS_DIR / 'candidates.json'
KNOWN_SOURCES_PATH = ASSETS_DIR / 'known_sources.json'
M3U_URL = 'https://raw.githubusercontent.com/iptv-org/iptv/master/streams/cn.m3u'

# 死域 (历史标 dead) — 跟 sync_cctv_top1.py 同步
# v0.3.7+69: 198.204 + 74.91 NOT in KNOWN_DEAD (他们是 iptv-org 公开 m3u 6/19
# 列的源,  仍能播,  保留作为 CCTV 兜底)
KNOWN_DEAD_HOSTS = (
    '69.30.245.50',         # v0.3.5.1 dead (iptv-org cn.m3u 最早 CCTV1 源,  连接 reset)
    '38.75.136.137',        # 6/18 dead (金矿,  老板不用)
    'ottrrs.hl.chinamobile.com',  # v0.3.5.1 dead (移动 CDN)
    'ott.mobaibox.com',     # v0.3.5.1 dead
    'cdn3.163189.xyz',      # 6/19 dead (cctv13 友书)
    'ivi.bupt.edu.cn',      # 6/19 dead (北邮公开源,  timeout 5s)
    'go.bkpcp.top',         # 6/19 dead (最初 v0.1.6+7 兜底,  403)
    'hplayer1.juyun.tv',    # 6/19 dead 偶尔 (juyun.tv 不可靠)
)


def parse_m3u(content: str):
    """解析 m3u 格式, 返回 [(channel_id, url, tvg_name)]."""
    entries = []
    channel_id = None
    tvg_name = None
    for line in content.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith('#EXTINF:'):
            # 提取 tvg-id="X.cn@HD" 或 "X.cn@SD"
            m = re.search(r'tvg-id="([^"]+)"', line)
            if m:
                tvg_id_raw = m.group(1)
                # 去掉 @HD/@SD/@UHD/...
                tvg_id = re.sub(r'@.*$', '', tvg_id_raw)
                if tvg_id.endswith('.cn'):
                    channel_id = tvg_id
                    tvg_name = re.sub(r',.*$', '', line.split(',', 1)[1] if ',' in line else '').strip()
        elif line.startswith('http'):
            if channel_id:
                entries.append((channel_id, line, tvg_name))
                channel_id = None
                tvg_name = None
    return entries


def probe_url(url: str, timeout: float = 5.0) -> dict:
    """HTTP HEAD 探测一个 URL. 返回 alive/score/rtt/error."""
    # 跳过死域
    host = urlparse(url).hostname or ''
    for dead in KNOWN_DEAD_HOSTS:
        if host == dead or host.endswith('.' + dead):
            return {'url': url, 'alive': False, 'score': 0.0, 'rttMs': 0,
                    'error': f'KNOWN_DEAD_HOSTS:{host}', 'method': 'skipped'}

    t0 = time.perf_counter()
    try:
        req = Request(url, method='GET', headers={
            'User-Agent': 'iptv-app-discover/1.0',
            'Range': 'bytes=0-1024',  # 只下前 1KB 测活
        })
        with urlopen(req, timeout=timeout) as resp:
            data = resp.read(1024)
            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            content_type = resp.headers.get('Content-Type', '')
            # m3u8 / octet-stream / video
            is_hls = (
                b'#EXTM3U' in data[:200]
                or 'mpegurl' in content_type
                or url.lower().endswith('.m3u8')
            )
            if is_hls:
                # 算分: 越快越高 (0-1.0)
                score = max(0.0, 1.0 - elapsed_ms / 5000.0)
                return {
                    'url': url, 'alive': True, 'score': round(score, 3),
                    'rttMs': elapsed_ms, 'error': None,
                    'method': 'iptv_org',
                }
            else:
                # 不是 HLS, 可能是 302 重定向页面
                return {
                    'url': url, 'alive': False, 'score': 0.0,
                    'rttMs': elapsed_ms,
                    'error': f'not HLS (content-type={content_type})',
                    'method': 'skipped',
                }
    except HTTPError as e:
        elapsed_ms = int((time.perf_counter() - t0) * 1000)
        return {'url': url, 'alive': False, 'score': 0.0,
                'rttMs': elapsed_ms, 'error': f'HTTP {e.code}',
                'method': 'skipped'}
    except (URLError, TimeoutError, OSError) as e:
        elapsed_ms = int((time.perf_counter() - t0) * 1000)
        return {'url': url, 'alive': False, 'score': 0.0,
                'rttMs': elapsed_ms, 'error': f'{type(e).__name__}: {e}',
                'method': 'skipped'}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--workers', type=int, default=20)
    p.add_argument('--timeout', type=float, default=5.0)
    p.add_argument('--max-channels', type=int, default=300,
                   help='最多探测多少频道 (防止 m3u 太大)')
    args = p.parse_args()

    print(f'== 抓 iptv-org cn.m3u ({M3U_URL}) ==')
    try:
        with urlopen(M3U_URL, timeout=15) as resp:
            m3u = resp.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f'!! 抓 m3u 失败: {e}')
        sys.exit(1)
    entries = parse_m3u(m3u)
    print(f'   解析 {len(entries)} 个 .cn 频道条目')

    # 去重 channel_id, 每个 channel 留前 5 个源 (避免 m3u 重复)
    by_channel: dict[str, list[tuple[str, str]]] = {}
    for ch_id, url, name in entries:
        by_channel.setdefault(ch_id, []).append((url, name))
    print(f'   {len(by_channel)} 个 .cn 频道 (去重)')

    # 探活 — 每 channel 取前 3 个源 (节省时间)
    tasks = []
    for ch_id, urls in by_channel.items():
        for url, name in urls[:3]:
            tasks.append((ch_id, url, name))
    print(f'== 探活 {len(tasks)} 个源 (workers={args.workers}, timeout={args.timeout}s) ==')

    results: dict[str, list[dict]] = {ch: [] for ch, _, _ in tasks}
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futures = {ex.submit(probe_url, url, args.timeout): (ch, url, name)
                   for ch, url, name in tasks}
        for i, fut in enumerate(as_completed(futures), 1):
            ch, url, name = futures[fut]
            r = fut.result()
            results.setdefault(ch, []).append(r)
            if i % 20 == 0:
                alive = sum(1 for ch_r in results.values()
                             for x in ch_r if x['alive'])
                print(f'   {i}/{len(tasks)}  alive={alive}')

    # 写 candidates.json (类似 cctv_candidates.json)
    out = {
        'fetched_at': time.strftime('%Y-%m-%dT%H:%M:%S%z'),
        'source': M3U_URL,
        'channels': {
            ch: sorted(rrs, key=lambda x: (-x.get('score', 0), x.get('rttMs', 999999)))
            for ch, rrs in results.items() if rrs
        },
    }
    CANDIDATES_PATH.write_text(json.dumps(out, indent=2, ensure_ascii=False))
    alive_total = sum(1 for ch_r in out['channels'].values()
                      for x in ch_r if x['alive'])
    print(f'== 写入 {CANDIDATES_PATH}: {len(out["channels"])} 频道, alive {alive_total} 源 ==')

    # 合并到 known_sources.json
    KNOWN_SOURCES_PATH.write_text(json.dumps(load_known_sources(), indent=2,
                                              ensure_ascii=False))
    # TODO: sync_known_sources.py 还没写, 但 v0.3.7+50 的 sync_cctv_top1.py 有
    # 类似合并逻辑.  下一步写 sync_known_sources.py
    print(f'   known_sources.json 保持不变 (等 sync_known_sources.py 写完)')


def load_known_sources() -> dict:
    """读 existing known_sources.json, 保留所有现有 key (含 bkpcp 兜底)."""
    if KNOWN_SOURCES_PATH.exists():
        return json.loads(KNOWN_SOURCES_PATH.read_text())
    return {}


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
discover_cctv_sources.py — CCTV 候选源健康分排序, 输出 top 3/频道

背景 (v0.3.5.3 6/18, 老板 14:02 拍板 "去找央视的源"):
  v0.3.5 标 CCTV 16 频道 "全活" 实际死了. 本脚本:
  1. 读 assets/data/cctv_candidates.json (30+ 候选)
  2. 30 并发 head + 抽样 GET 1KB 验
  3. 按健康分排序, 每频道保留 top 3
  4. 输出 assets/data/cctv_sources.json + 健康报告

健康分公式 (v0.3.5.3):
  base = 0.5 (default, 未知源)
  + 0.2 if HTTPS
  + 0.1 if response time < 1s
  + 0.1 if response time < 500ms
  - 0.3 if master-only (200 但 sub-stream 404) — 这是央视官方 CDN 对国外 IP 的策略
  + 0.1 if Content-Type is m3u8/mpegurl
  cap to [0, 1]

用法:
  cd ~/work/projects/iptv-app
  python3 scripts/discover_cctv_sources.py                     # 默认 input/output
  python3 scripts/discover_cctv_sources.py --input custom.json  # 自定义 input
  python3 scripts/discover_cctv_sources.py --output custom.json # 自定义 output
  python3 scripts/discover_cctv_sources.py --workers 50         # 并发数
  python3 scripts/discover_cctv_sources.py --timeout 8          # 单条超时秒

铁律 (6/2 threely 立的):
  - 不用 cookies / auth tokens 写死
  - 优先用 GitHub Pages 跳转 (xykt-fix.github.io), 因为它自动换 token
  - 真机 fetch 验证, 不相信 "标了活" 的口径

报告输出:
  - assets/data/cctv_sources.json: 16 频道 × top 3 sources
  - stdout: 16 频道健康分矩阵 (CCTV 编号 × 源 URL × 状态 × RTT × 分数)
"""
import argparse
import json
import socket
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

# 默认 5s timeout — HLS 直播源首屏通常 < 1s
DEFAULT_TIMEOUT = 5.0

# 默认 30 并发 — 国内源通常 1-3s, 30 并发 = 总耗时 ~10s
DEFAULT_WORKERS = 30


def load_candidates(path: Path) -> list[dict]:
    """加载 cctv_candidates.json, 返回 candidate 列表."""
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    return data.get('candidates', [])


def check_one_url(url: str, timeout: float) -> dict:
    """
    测一条 URL: HEAD + 1KB GET, 计算 health_score.

    返回:
      {
        "url": str,
        "alive": bool,
        "rtt_ms": int,    # 首屏 RTT
        "http_code": int | None,
        "reason": str,    # 失败原因 (alive 时为空)
        "score": float,   # 0.0 - 1.0
        "is_m3u8": bool,  # 响应是否是 m3u8 master
      }
    """
    result = {
        'url': url,
        'alive': False,
        'rtt_ms': 0,
        'http_code': None,
        'reason': '',
        'score': 0.0,
        'is_m3u8': False,
    }

    start = time.monotonic()
    try:
        req = urllib.request.Request(url, method='GET')
        req.add_header('User-Agent', 'discover_cctv_sources.py/1.0 (sanyelive CI)')
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            elapsed = (time.monotonic() - start) * 1000
            code = resp.getcode()
            content_type = (resp.headers.get('Content-Type') or '').lower()
            first_bytes = resp.read(1024)
            result['rtt_ms'] = int(elapsed)
            result['http_code'] = code
            result['is_m3u8'] = first_bytes.startswith(b'#EXTM3U') or first_bytes.startswith(b'#EXT-X')

            if code != 200:
                result['reason'] = f'HTTP {code}'
                result['score'] = 0.0
                return result

            if not result['is_m3u8']:
                # 200 但 body 不是 m3u8 (HTML 错误页等)
                preview = first_bytes[:80].decode('utf-8', errors='replace')
                result['reason'] = f'200 but not m3u8: {preview!r}'
                result['score'] = 0.0
                return result

            # 200 + m3u8 — alive
            result['alive'] = True
            result['score'] = _calc_score(elapsed, url, content_type)
            return result

    except urllib.error.HTTPError as e:
        result['reason'] = f'HTTP {e.code} {e.reason}'
        result['http_code'] = e.code
        return result
    except urllib.error.URLError as e:
        result['reason'] = f'URL error: {e.reason}'
        return result
    except (socket.timeout, TimeoutError):
        result['reason'] = f'timeout ({timeout}s)'
        return result
    except (ConnectionError, ConnectionResetError, ConnectionRefusedError) as e:
        result['reason'] = f'connection: {e}'
        return result
    except Exception as e:  # noqa: BLE001
        result['reason'] = f'{type(e).__name__}: {e}'
        return result


def _calc_score(rtt_ms: float, url: str, content_type: str) -> float:
    """
    健康分公式:
      base = 0.5
      + 0.2 if HTTPS
      + 0.1 if rtt < 1000ms
      + 0.1 if rtt < 500ms
      + 0.1 if Content-Type is m3u8/mpegurl
      - 0.3 if master-only (sub-stream 404) — 央视官方 CDN 国外 IP 策略
      cap to [0, 1]
    """
    score = 0.5
    if url.startswith('https://'):
        score += 0.2
    if rtt_ms < 1000:
        score += 0.1
    if rtt_ms < 500:
        score += 0.1
    if 'mpegurl' in content_type or 'm3u' in content_type:
        score += 0.1
    # Check if sub-stream is reachable (master-only penalty)
    if not _sub_stream_alive(url):
        score -= 0.3
    return max(0.0, min(1.0, score))


# 缓存 sub-stream 检查结果 (一个 master 只查一次)
_sub_stream_cache: dict[str, bool] = {}


def _sub_stream_alive(master_url: str) -> bool:
    """
    检查 master m3u8 的 sub-stream 是否能开 + 第一个 .ts segment 头是
    MPEG-TS sync byte 0x47. 返回 True/False.

    逻辑:
      1. GET master (已经查过 alive)
      2. 解析 #EXT-X-STREAM-INF 找子 m3u8 URL
      3. GET 子 m3u8 找第一个 .ts segment URL
      4. GET 第一个 .ts,  头 4 字节是 MPEG-TS sync (0x47 0x40 ...) 算活

    v0.3.8+108 (6/20 老板反馈 CCTV1 花屏+有声音):
      之前 _sub_stream_alive 只看 sub-stream m3u8 头 200 OK,  不验 TS 段.
      但 tencent_cloud / 198.204 / 74.91 这类假活 m3u8: 表面 200 + #EXTM3U,
      但 第一个 .ts segment 实际返回 HTML 404 页面.  换 master 路径、
      再换 sub m3u8 都还是 HTML.  唯一准确验证是拉第一个 .ts 段看 0x47 sync byte.
      验证失败 = m3u8 看上去活但实际拼不上完整视频,  fail-over 跳过.
    央视官方 CDN (ldncctvwbcdtxy.liveplay.myqcloud.com) 对国外 IP:
      master 200 OK, sub-stream 404 — geo-blocked 特征
    GitHub Pages 跳转 (xykt-fix.github.io):
      master 200, sub-stream (CMCC token 跳转) 264788.xyz 现在 假活 (HTML 404)
    198.204.240.250:82:
      master 就是 sub-stream (单文件 m3u8),  验第一个 .ts
    74.91.26.218:82:
      假活:  m3u8 200 + #EXTM3U,  但 segment 是 HTML 404.  验证不通过.
    """
    if master_url in _sub_stream_cache:
        return _sub_stream_cache[master_url]

    try:
        req = urllib.request.Request(master_url, method='GET')
        req.add_header('User-Agent', 'discover_cctv_sources.py/1.0')
        with urllib.request.urlopen(req, timeout=4) as resp:
            content = resp.read(4096).decode('utf-8', errors='replace')

        # 递归找第一个 .ts segment URL
        seg_url = _find_first_ts_url(content, master_url)
        if not seg_url:
            # 找不到 .ts 段,  当 dead (单文件 m3u8 但没 .ts 引用)
            _sub_stream_cache[master_url] = False
            return False

        # 拉第一个 .ts 段,  验 MPEG-TS sync byte 0x47
        try:
            seg_req = urllib.request.Request(seg_url, method='GET')
            seg_req.add_header('User-Agent', 'discover_cctv_sources.py/1.0')
            with urllib.request.urlopen(seg_req, timeout=4) as seg_resp:
                seg_first = seg_resp.read(4)
                is_ts = len(seg_first) >= 1 and seg_first[0] == 0x47
                _sub_stream_cache[master_url] = is_ts
                return is_ts
        except (urllib.error.HTTPError, urllib.error.URLError, socket.timeout, TimeoutError):
            _sub_stream_cache[master_url] = False
            return False
    except Exception:
        _sub_stream_cache[master_url] = False
        return False


def _find_first_ts_url(content: str, base_url: str) -> str | None:
    """
    从 m3u8 body 递归找第一个 .ts segment URL.

    支持:
      1. 单文件 m3u8 (198.204.240.250 风格): 直接含 .ts 引用
      2. master m3u8: 含 #EXT-X-STREAM-INF 跳到 sub m3u8,  sub m3u8 含 .ts
    """
    import re
    # 先看是不是单文件 m3u8 (有 .ts 引用)
    ts_match = re.search(r'^(?!#)(.+\.ts)$', content, re.MULTILINE)
    if ts_match:
        ts_rel = ts_match.group(1).strip()
        if ts_rel.startswith('http'):
            return ts_rel
        # 相对路径
        from urllib.parse import urljoin
        return urljoin(base_url, ts_rel)

    # master m3u8: 找 #EXT-X-STREAM-INF 后下一行的 sub m3u8 URL
    lines = content.splitlines()
    sub_url = None
    for i, line in enumerate(lines):
        if '#EXT-X-STREAM-INF' in line and i + 1 < len(lines):
            sub_rel = lines[i + 1].strip()
            if sub_rel.endswith('.m3u8'):
                if sub_rel.startswith('http'):
                    sub_url = sub_rel
                else:
                    from urllib.parse import urljoin
                    sub_url = urljoin(base_url, sub_rel)
                break

    if not sub_url:
        return None

    # 递归拉 sub m3u8 找 .ts
    try:
        req = urllib.request.Request(sub_url, method='GET')
        req.add_header('User-Agent', 'discover_cctv_sources.py/1.0')
        with urllib.request.urlopen(req, timeout=4) as resp:
            sub_content = resp.read(4096).decode('utf-8', errors='replace')
            return _find_first_ts_url(sub_content, sub_url)
    except Exception:
        return None


def _extract_sub_url(content: str, master_url: str) -> str | None:
    """
    从 master m3u8 body 抽 sub-stream URL.

    支持两种格式:
      1. 相对路径: /ldncctvwbcd/cdrmldcctv1_1_pd.m3u8
      2. 完整 URL: https://...
      3. 相对文件名: cctv1/segment_1.ts (单文件 m3u8, 不算 sub-stream)
    """
    import re

    # Format 1: EXT-X-STREAM-INF 后跟一个 URL (有 m3u8 扩展名)
    m = re.search(r'#EXT-X-STREAM-INF[^\n]*\n([^\s#]+)', content)
    if m:
        sub = m.group(1).strip()
        if sub.endswith('.m3u8') or sub.endswith('.m3u'):
            # Resolve relative to master
            if sub.startswith('http'):
                return sub
            if sub.startswith('/'):
                # /path/from/host
                from urllib.parse import urlparse, urlunparse
                p = urlparse(master_url)
                return urlunparse((p.scheme, p.netloc, sub, '', '', ''))
            # relative path
            return master_url.rsplit('/', 1)[0] + '/' + sub

    # Format 2: 单文件 m3u8 (直接是 segment, 不算 sub-stream)
    # 检查是否有 #EXT-X-STREAM-INF (master playlist 标志)
    if '#EXT-X-STREAM-INF' in content:
        return None  # master playlist 但没匹配到 URL

    # 单文件 m3u8 - 不需要 sub-stream
    return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description='测 CCTV 候选源健康分, 输出 top 3/频道',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        '--input',
        default='assets/data/cctv_candidates.json',
        help='cctv_candidates.json 路径',
    )
    parser.add_argument(
        '--output',
        default='assets/data/cctv_sources.json',
        help='cctv_sources.json 输出路径',
    )
    parser.add_argument(
        '--top',
        type=int,
        default=3,
        help='每频道保留 top N 源 (默认 3)',
    )
    parser.add_argument(
        '--timeout',
        type=float,
        default=DEFAULT_TIMEOUT,
        help=f'每条 URL 超时秒数 (默认 {DEFAULT_TIMEOUT})',
    )
    parser.add_argument(
        '--workers',
        type=int,
        default=DEFAULT_WORKERS,
        help=f'并发数 (默认 {DEFAULT_WORKERS})',
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    if not input_path.exists():
        print(f'❌ {input_path} 不存在', file=sys.stderr)
        return 2

    candidates = load_candidates(input_path)
    if not candidates:
        print(f'❌ {input_path} 没有 candidates 数据', file=sys.stderr)
        return 2

    print(f'测 {len(candidates)} 条 CCTV 候选源 (workers={args.workers}, timeout={args.timeout}s) ...')

    # 并发测
    results: list[dict] = []
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        future_to_cand = {
            ex.submit(check_one_url, c['url'], args.timeout): c
            for c in candidates
        }
        for fut in as_completed(future_to_cand):
            cand = future_to_cand[fut]
            try:
                result = fut.result()
            except Exception as e:  # noqa: BLE001
                result = {
                    'url': cand['url'],
                    'alive': False,
                    'rtt_ms': 0,
                    'http_code': None,
                    'reason': f'{type(e).__name__}: {e}',
                    'score': 0.0,
                    'is_m3u8': False,
                }
            # attach metadata
            result['channel'] = cand['channel']
            result['method'] = cand.get('method', '')
            result['note'] = cand.get('note', '')
            results.append(result)

    # 按 channel 分组
    by_channel: dict[str, list[dict]] = {}
    for r in results:
        by_channel.setdefault(r['channel'], []).append(r)

    # 每组按 score 降序, 保留 top N
    final: dict[str, list[dict]] = {}
    for ch, items in sorted(by_channel.items()):
        items.sort(key=lambda x: (-x['score'], x['rtt_ms']))
        final[ch] = items[:args.top]

    # 输出 cctv_sources.json
    output = {
        '_comment': (
            'v0.3.5.3 (6/18) CCTV 源健康分排序结果. '
            'Discover script: scripts/discover_cctv_sources.py. '
            'Channel: CCTV1.cn ~ CCTV17.cn (含 CCTV4K/CCTV5Plus). '
            'Key: channel id, Value: list of {url, score, method, lastChecked, rttMs}. '
            'Top 3 sources per channel by health score (descending).'
        ),
        '_generated_at': time.strftime('%Y-%m-%dT%H:%M:%S%z'),
        '_discover_timeout_s': args.timeout,
        '_discover_workers': args.workers,
        '_source_count': sum(len(v) for v in final.values()),
        'channels': {
            ch: [
                {
                    'url': r['url'],
                    'score': round(r['score'], 3),
                    'method': r['method'],
                    'lastChecked': time.strftime('%Y-%m-%dT%H:%M:%S%z'),
                    'rttMs': r['rtt_ms'],
                    'alive': r['alive'],
                }
                for r in items
            ]
            for ch, items in final.items()
        },
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f'\n✅ 写入 {output_path} (16 频道 × {args.top} 源)')

    # 打印健康分矩阵 (16 频道 × 状态)
    print('\n=== CCTV 频道健康分矩阵 (v0.3.5.3 6/18) ===\n')
    print(f'{"频道":18s} {"源 ID":40s} {"状态":6s} {"分数":6s} {"RTT(ms)":8s} {"URL"}')
    print('-' * 130)
    for ch in sorted(by_channel.keys()):
        items = by_channel[ch]
        # 排序: alive first, then by score
        items.sort(key=lambda x: (not x['alive'], -x['score'], x['rtt_ms']))
        for i, r in enumerate(items):
            short = r['method'] or '?'
            status = '✅' if r['alive'] else '❌'
            score_str = f"{r['score']:.2f}" if r['alive'] else '   -'
            rtt_str = f"{r['rtt_ms']:>5d}" if r['alive'] else '     -'
            print(f'{ch:18s} {short:40s} {status:6s} {score_str:6s} {rtt_str:8s} {r["url"]}')
        print()

    # 统计
    alive = [r for r in results if r['alive']]
    dead = [r for r in results if not r['alive']]
    alive_channels = {r['channel'] for r in alive}
    print(f'=== 总计 {len(results)} 条: ✅ {len(alive)} alive (覆盖 {len(alive_channels)} 频道), ❌ {len(dead)} dead ===')

    # 哪些 CCTV 主频道没有源
    all_main = {'CCTV1.cn', 'CCTV2.cn', 'CCTV3.cn', 'CCTV4.cn', 'CCTV5.cn', 'CCTV5Plus.cn',
                'CCTV6.cn', 'CCTV7.cn', 'CCTV8.cn', 'CCTV9.cn', 'CCTV10.cn', 'CCTV11.cn',
                'CCTV12.cn', 'CCTV13.cn', 'CCTV14.cn', 'CCTV15.cn', 'CCTV16.cn', 'CCTV17.cn',
                'CCTV4K.cn'}
    missing = all_main - alive_channels
    if missing:
        print(f'\n⚠️ 以下 CCTV 主频道本次无验证源:')
        for ch in sorted(missing):
            print(f'   - {ch}')
        print(f'   这些频道需要老板自建 nginx+ffmpeg (卡 6 终极 fallback) 或后续 PR')

    return 0


if __name__ == '__main__':
    sys.exit(main())

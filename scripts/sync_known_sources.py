#!/usr/bin/env python3
"""v0.3.7+69: sync_known_sources.py — 把 discover_known_sources.py 探测的 candidates
合并到 assets/data/known_sources.json, 按 score 排序 top-2 per channel.

老板 6/19 16:47 反馈: '那第一版用的央视源哪里来的 可以播放的啊'
修法: 抓 iptv-org cn.m3u 重新探测,  按 score 合并,  保留老 bkpcp/bupt 兜底.

合并规则 (类似 sync_cctv_top1.py):
1. candidates.json alive top-1 URL → known_sources.json top-1
2. candidates.json alive top-2 (if any) → known_sources.json top-2
3. 已存在的 known_sources.json URL → 保留 (老源可能仍能用)
4. 不引入 KNOWN_DEAD_HOSTS 里的源
5. 改 known_sources.json 后, 跑 channel_repository.dart 重新注入

注意: 改 known_sources.json 后,  还需要 git push 触发 CI 重新打包 APK.
老板装机测才能验证 3s 规则 + green-screen fix.
"""
import argparse
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / 'assets' / 'data'
CANDIDATES_PATH = ASSETS_DIR / 'candidates.json'
KNOWN_SOURCES_PATH = ASSETS_DIR / 'known_sources.json'

# 跟 discover_known_sources.py 同步
KNOWN_DEAD_HOSTS = (
    '69.30.245.50',
    '38.75.136.137',
    'ottrrs.hl.chinamobile.com',
    'ott.mobaibox.com',
    'cdn3.163189.xyz',
    'ivi.bupt.edu.cn',
    'go.bkpcp.top',
    'hplayer1.juyun.tv',
)

# 兜底老源 — 死透也保留 (历史标识, sync_known_sources 走)
FALLBACK_OLD_SOURCES = {
    # 之前 v0.1.6+7 bkpcp.top 公开源 — 6/19 dead,  但保留作为 history trace
    'CCTV1.cn': ['http://go.bkpcp.top/mg/CCTV1'],
    'CCTV2.cn': ['http://go.bkpcp.top/mg/CCTV2'],
    'CCTV3.cn': ['http://go.bkpcp.top/mg/CCTV3'],
    'CCTV4Asia.cn': ['http://go.bkpcp.top/mg/CCTV4Asia'],
    'CCTV4K.cn': ['http://go.bkpcp.top/mg/CCTV4K'],
    'CCTV5.cn': ['http://go.bkpcp.top/mg/CCTV5'],
    'CCTV5Plus.cn': ['http://go.bkpcp.top/mg/CCTV5Plus'],
    'CCTV6.cn': ['http://go.bkpcp.top/mg/CCTV6'],
    'CCTV7.cn': ['http://go.bkpcp.top/mg/CCTV7'],
    'CCTV8.cn': ['http://go.bkpcp.top/mg/CCTV8'],
    'CCTV8K.cn': ['http://go.bkpcp.top/mg/CCTV8K'],
    'CCTV9.cn': ['http://go.bkpcp.top/mg/CCTV9'],
    'CCTV10.cn': ['http://go.bkpcp.top/mg/CCTV10'],
    'CCTV11.cn': ['http://go.bkpcp.top/mg/CCTV11'],
    'CCTV12.cn': ['http://go.bkpcp.top/mg/CCTV12'],
    'CCTV13.cn': ['http://go.bkpcp.top/mg/CCTV13'],
    'CCTV14.cn': ['http://go.bkpcp.top/mg/CCTV14'],
    'CCTV15.cn': ['http://go.bkpcp.top/mg/CCTV15'],
    'CCTV16.cn': ['http://go.bkpcp.top/mg/CCTV16'],
    'CCTV17.cn': ['http://go.bkpcp.top/mg/CCTV17'],
}


def is_dead_host(url: str) -> bool:
    from urllib.parse import urlparse
    host = urlparse(url).hostname or ''
    return any(host == d or host.endswith('.' + d) for d in KNOWN_DEAD_HOSTS)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--max-per-channel', type=int, default=3,
                   help='每个频道最多 top-N (默认 3)')
    p.add_argument('--dry-run', action='store_true',
                   help='只打印 diff, 不写文件')
    args = p.parse_args()

    candidates = json.loads(CANDIDATES_PATH.read_text())
    known = json.loads(KNOWN_SOURCES_PATH.read_text())

    changes = []
    new_keys = []

    for ch_id, sources in candidates.get('channels', {}).items():
        # 1. candidates alive top-N (按 score)
        alive_top = []
        for s in sorted(sources, key=lambda x: (-x.get('score', 0), x.get('rttMs', 999999))):
            if s.get('alive') and not is_dead_host(s['url']):
                alive_top.append(s['url'])
            if len(alive_top) >= args.max_per_channel:
                break

        # 2. 已存在 known_sources.json 里的 URL (保留老兜底)
        existing = list(known.get(ch_id, []))
        # 3. 兜底 bkpcp
        fallback = FALLBACK_OLD_SOURCES.get(ch_id, [])

        # 合并: alive top → existing (filter dead) → fallback
        seen = set()
        merged = []
        for u in alive_top + existing + fallback:
            if u not in seen and not is_dead_host(u):
                seen.add(u)
                merged.append(u)

        # 跟老比较
        old_list = known.get(ch_id, [])
        if merged != old_list:
            known[ch_id] = merged
            changes.append((ch_id, old_list, merged))
            if ch_id not in known:
                new_keys.append(ch_id)

    print(f'== 改动 {len(changes)} 个频道 ==')
    for ch_id, old, new in changes[:20]:
        print(f'  ✏️ {ch_id:30s}')
        if old:
            print(f'     old ({len(old)}): {old[:2]}')
        else:
            print(f'     old: 0 (新增)')
        print(f'     new ({len(new)}): {new[:2]}')
    if len(changes) > 20:
        print(f'  ... 还有 {len(changes)-20} 个')

    print(f'\n== 新增频道 {len(new_keys)} 个 (iptv-org 6/19 探测有源) ==')
    for k in new_keys[:10]:
        print(f'  + {k}: {known[k][:2]}')
    if len(new_keys) > 10:
        print(f'  ... 还有 {len(new_keys)-10} 个')

    if args.dry_run:
        print('\n(dry-run, 未写文件)')
        return

    KNOWN_SOURCES_PATH.write_text(json.dumps(known, indent=2, ensure_ascii=False))
    print(f'\n✅ 写入 {KNOWN_SOURCES_PATH}: {len(known)} 频道')


if __name__ == '__main__':
    main()

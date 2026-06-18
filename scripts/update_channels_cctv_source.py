#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
update_channels_cctv_source.py — 把 cctv_sources.json top 1 源写到
channels_cn.json 的 cctvSource 字段 (CCTV 主频道).

这是 v0.3.5.3 (6/18) CCTV hotfix 配套脚本, 给 16 个 CCTV 主频道:
  - CCTV1~17 (CCTV-1 综合 到 CCTV-17 农业农村)
  - CCTV4K (超高清)
  - CCTV5Plus (体育赛事)
加上 cctvSource 字段, 跟现有 sources 字段并存, 播放时 SourceDispatcher
走 cctvSource 优先.

跑法:
  python3 scripts/update_channels_cctv_source.py
  # 幂等, 已加过 cctvSource 字段的不会覆盖 (除非 --force)

输出: 原地改写 assets/data/channels_cn.json
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
CHANNELS = ROOT / 'assets/data/channels_cn.json'
CCTV_SOURCES = ROOT / 'assets/data/cctv_sources.json'

# v0.3.5.3 目标 18 频道 (16 主 + 4K + 5Plus)
CCTV_MAIN = [
    'CCTV1.cn', 'CCTV2.cn', 'CCTV3.cn', 'CCTV4.cn', 'CCTV5.cn', 'CCTV5Plus.cn',
    'CCTV6.cn', 'CCTV7.cn', 'CCTV8.cn', 'CCTV9.cn', 'CCTV10.cn', 'CCTV11.cn',
    'CCTV12.cn', 'CCTV13.cn', 'CCTV14.cn', 'CCTV15.cn', 'CCTV16.cn', 'CCTV17.cn',
    'CCTV4K.cn',
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--force', action='store_true',
                        help='覆盖已有 cctvSource 字段')
    parser.add_argument('--top', type=int, default=1,
                        help='每频道加几个 cctvSource (默认 1, top 1 = 健康分最高)')
    args = parser.parse_args()

    if not CHANNELS.exists():
        print(f'❌ {CHANNELS} 不存在', file=sys.stderr)
        return 1
    if not CCTV_SOURCES.exists():
        print(f'❌ {CCTV_SOURCES} 不存在 (先跑 scripts/discover_cctv_sources.py)', file=sys.stderr)
        return 1

    with open(CHANNELS, encoding='utf-8') as f:
        channels = json.load(f)
    with open(CCTV_SOURCES, encoding='utf-8') as f:
        cctv = json.load(f)

    cctv_by_channel = cctv.get('channels', {})

    added = 0
    skipped = 0
    no_source = 0
    for ch in channels:
        cid = ch.get('id', '')
        if cid not in CCTV_MAIN:
            continue
        existing = ch.get('cctvSource', [])
        if existing and not args.force:
            skipped += 1
            continue
        sources = cctv_by_channel.get(cid, [])
        alive = [s for s in sources if s.get('alive')]
        top = alive[:args.top]
        if not top:
            no_source += 1
            print(f'  ⚠️ {cid}: cctv_sources.json 里没有 alive 源, 跳过', file=sys.stderr)
            continue
        urls = [s['url'] for s in top]
        ch['cctvSource'] = urls
        added += 1
        # 调试打印
        for s in top:
            print(f'  ✅ {cid:14s} score={s["score"]:.2f} rtt={s["rttMs"]:>4d}ms  {s["url"]}')

    print(f'\n写入 {CHANNELS}: 新增 cctvSource {added} 频道, 跳过 {skipped}, 无源 {no_source}')

    with open(CHANNELS, 'w', encoding='utf-8') as f:
        json.dump(channels, f, ensure_ascii=False, indent=2)

    return 0


if __name__ == '__main__':
    sys.exit(main())

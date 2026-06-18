#!/usr/bin/env python3
"""把 known_sources.json 的 source URL 合并进 channels_cn.json 对应 channel 的 sources 字段.

P2-2-A 数据合并 (老板 6/18 10:36 拍板 拆 A+B).

只读 known_sources.json + channels_cn.json, 写出合并后的 channels_cn.json.
不动 lib/, 不动 pubspec, 不动 player_page / player_service.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHANNELS = ROOT / 'assets/data/channels_cn.json'
KNOWN = ROOT / 'assets/data/known_sources.json'
TODAY = '2026-06-18'


def load():
    with open(CHANNELS, encoding='utf-8') as f:
        channels = json.load(f)
    with open(KNOWN, encoding='utf-8') as f:
        known = json.load(f)
    return channels, known


def build_candidates(ch):
    """给一个 channel 列出所有可能的 known_sources key (带 .cn 后缀).

    优先规则:
      1. channel['id'] (e.g. 'CCTV5.cn', 'AnhuiSatelliteTV.cn') — 直配
      2. name 形如 'CCTV-5' / 'CCTV-5+' / 'CCTV-4 Asia' → CCTV5 / CCTV5Plus / CCTV4Asia
    """
    candidates = [ch['id']]
    name = ch.get('name', '')

    # CCTV name-based alias (channels_cn 用 'CCTV-5', known 用 'CCTV5.cn')
    if name.startswith('CCTV-'):
        num = name[5:].strip()  # '5' / '5+' / '4 America' / '4K' / 'Billiards'
        # 纯数字 → CCTV{n}
        clean = num.rstrip('+').strip()
        if clean.isdigit():
            candidates.append(f'CCTV{clean}')
        # '+' 后缀 → CCTV5Plus (体育赛事)
        if name.endswith('+') or num.endswith('+'):
            candidates.append('CCTV5Plus')
        # 4K / 8K / WomensFashion 之类
        if '4K' in name:
            candidates.append('CCTV4K')
        if '8K' in name:
            candidates.append('CCTV8K')
        if 'WomensFashion' in name:
            candidates.append('CCTVWomensFashion')
        # CCTV-4 America / Europe / Asia → CCTV4Asia (默认 Asia)
        if 'Asia' in name:
            candidates.append('CCTV4Asia')

    # 全部补 .cn
    return [c if c.endswith('.cn') else f'{c}.cn' for c in candidates]


def merge(channels, known):
    """对 channels 里所有能找到 known key 的 channel, 写入 sources."""
    merged = 0
    no_match = []
    for ch in channels:
        candidates = build_candidates(ch)
        matched_key = None
        for key in candidates:
            if key in known:
                matched_key = key
                break
        if matched_key is None:
            no_match.append(ch)
            continue
        urls = known[matched_key]
        if isinstance(urls, str):
            urls = [urls]
        ch['sources'] = [{'url': u, 'type': 'hls'} for u in urls]
        ch['source_updated_at'] = TODAY
        merged += 1
    return merged, no_match


def verify(channels):
    """打印合并情况, 返回是否全部 CCTV + 全部已知 卫视 channel 都拿到源."""
    cctv = [c for c in channels if c['id'].startswith('CCTV') and c['id'][4:6] not in ('Pl', 'Bi', 'En', 'Go', 'Op', 'St', 'Th', 'We', 'Wo')]
    # ↑ 简版: 取 id 是 CCTV<数字> / CCTV4K / CCTV5Plus / CCTV4Asia / CCTV8K / CCTVWomensFashion
    cctv_main = [
        c for c in channels
        if c['id'].startswith('CCTV')
        and c['id'] not in {
            'CCTVPlus1.cn', 'CCTVPlus2.cn',
            'CCTV4America.cn', 'CCTV4Europe.cn',
            'CCTVBilliards.cn', 'CCTVEntertainment.cn',
            'CCTVGolfTennis.cn', 'CCTVOpera.cn',
            'CCTVStormFootball.cn', 'CCTVStormMusic.cn', 'CCTVStormTheater.cn',
            'CCTVTheFirstTheater.cn', 'CCTVWeaponTechnology.cn', 'CCTVWorldGeography.cn',
        }
    ]
    sat = [c for c in channels if 'SatelliteTV' in c.get('id', '')]
    sat_with = [c for c in sat if c.get('sources')]
    other_with = [c for c in channels if c.get('sources') and c not in cctv_main and c not in sat]

    print('--- CCTV 主频道 ---')
    for c in cctv_main:
        n = len(c.get('sources', []))
        flag = '✅' if n > 0 else '❌'
        print(f'  {flag} {c["id"]:<24} name={c["name"]!r:<24} sources={n}')

    print('--- 卫视 (Satellite TV) ---')
    for c in sat:
        n = len(c.get('sources', []))
        flag = '✅' if n > 0 else '❌'
        print(f'  {flag} {c["id"]:<48} sources={n}')

    print(f'--- 其他 (有源) ---')
    print(f'  {len(other_with)} channels')

    cctv5 = next((c for c in channels if c['id'] == 'CCTV5.cn'), None)
    cctv5_count = len(cctv5['sources']) if cctv5 else 0
    print()
    print(f'CCTV-5 sources: {cctv5_count}')
    print(f'CCTV 主频道有源: {sum(1 for c in cctv_main if c.get("sources"))}/{len(cctv_main)}')
    print(f'卫视有源: {len(sat_with)}/{len(sat)}')
    print(f'其他有源: {len(other_with)}')

    return cctv5_count > 0 and len(sat_with) >= 1  # 至少 CCTV5 有源 + 至少 1 个 卫视有源


def main():
    channels, known = load()
    print(f'Total channels: {len(channels)}')
    print(f'Total known keys: {len(known)}')

    merged, no_match = merge(channels, known)
    print(f'Merged {merged}/{len(channels)} channels')
    if no_match:
        # 打印前 20 个没匹配上的 id
        print(f'No-match sample (前 20): {[c["id"] for c in no_match[:20]]}')

    ok = verify(channels)

    # 保持原文件紧凑格式 (单行 JSON), 最小化 git diff.
    # 跟原 git tracked 文件的格式一致 (no indent, default separators)
    with open(CHANNELS, 'w', encoding='utf-8') as f:
        json.dump(channels, f, ensure_ascii=False, separators=(',', ':'))
    print(f'\nWritten to {CHANNELS} (compact format)')

    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())

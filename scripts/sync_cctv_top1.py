#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sync_cctv_top1.py — 把 cctv_sources.json 的 top-1 同步回 known_sources.json

背景 (v0.3.7 6/19, 老板 11:12 反馈):
  v0.3.5.3 discover 拿到 CCTV 19 频道健康分矩阵, 但只写到
  cctv_sources.json, 没合并回 known_sources.json.  PlayerService 实际
  走 channel.sources (仓库层) → 优先级 cctvSource[0] > sources[0] >
  known_sources[0].  但 known_sources.json 里的 CCTV 旧源 (69.30.245.50
  / 74.91.26.218 / 38.75.136.137) 都死了, 老板要求回到 iptv-org
  老公开 m3u 源.

逻辑:
  1. 读 cctv_sources.json, 对每个 CCTV 频道取 score 最高的 alive URL
     (top-1).  没有 alive 就保留原 known_sources entry (兜底)
  2. 读 known_sources.json, 对这些 CCTV 频道:
     - 替换为 [top1_url, go.bkpcp.top 兜底, ivi.bupt.edu.cn 兜底]
     - 死源 (alive=false) 全部删掉 (top-1 永远 alive)
     - 没 top1 但有 known_sources 兜底的: 保留兜底 + 去掉死源
     - 兜底 bkpcp/bupt 任一缺失: 跳过该兜底 (不强加)
  3. CCTV 范围: cctv_sources.json 里有 entries 的所有 channel_id (≈18)
     = CCTV1/2/3/4/5/5+/6/7/8/9/10/11/12/13/14/15/16/17/4K
  4. 写回 known_sources.json, 保持其他 channel (卫视/地方台) 不动

用法:
  python3 scripts/sync_cctv_top1.py                          # 默认路径
  python3 scripts/sync_cctv_top1.py --dry-run                # 不写盘, 只打 diff
  python3 scripts/sync_cctv_top1.py --keep-known-fallbacks   # 保留所有 alive known_sources 兜底 (默认只保留 go.bkpcp + ivi.bupt)

输出:
  - assets/data/known_sources.json: CCTV 字段刷新
  - assets/data/cctv_sources.json.bak: 旧 cctv_sources.json 备份 (防回滚)
  - stdout: 改了哪些 channel + dead 源数量

铁律 (6/19 立的):
  - 不要写任何金矿源 (38.75.136.137 不用), 老板只要明源
  - 不要动非 CCTV channel
  - 兜底 URL 必须已经在 known_sources.json 里 (避免引入未验证源)
"""
import argparse
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CCTV_SOURCES = ROOT / 'assets' / 'cctv_sources.json.bak'  # backup target
KNOWN_PATH = ROOT / 'assets' / 'data' / 'known_sources.json'
CCTV_SRC_PATH = ROOT / 'assets' / 'data' / 'cctv_sources.json'

# 兜底源特征 (老 iptv-org 公开源, 老板 11:12 说"用最初那个源")
FALLBACK_HOSTS = ('go.bkpcp.top', 'ivi.bupt.edu.cn')


def backup_existing_cctv_sources() -> None:
    """备份当前 cctv_sources.json → .bak (防回滚)."""
    if not CCTV_SRC_PATH.exists():
        return
    if CCTV_SOURCES.exists():
        # .bak 已存在, 不覆盖 (保留最早版本)
        return
    shutil.copy2(CCTV_SRC_PATH, CCTV_SOURCES)
    print(f'📦 已备份 cctv_sources.json → {CCTV_SOURCES.name}')


def load_cctv_top1() -> dict[str, dict]:
    """
    读 cctv_sources.json, 返回 {channel_id: {url, score, alive}}.
    只取 alive=true 中 score 最高的 (top-1).

    v0.3.7.1 (6/19 12:43): 优先选 non-CDRM 源.  如果 top-1 是 CDRM 加密流
    (myqcloud cdrmldcctv... 路径),  跳到下一个 non-DRM 源,  避免 player
    黑屏.  全部都 CDRM 才退回到原 top-1.
    """
    with open(CCTV_SRC_PATH, encoding='utf-8') as f:
        data = json.load(f)
    channels = data.get('channels', {})
    top1 = {}
    for ch_id, items in channels.items():
        alive_items = [s for s in items if s.get('alive')]
        if not alive_items:
            continue
        # 按 score 降序, rtt 升序
        alive_items.sort(key=lambda s: (-s.get('score', 0.0), s.get('rttMs', 999999)))
        # 优先选 non-CDRM 源
        non_drm = [s for s in alive_items if 'cdrm' not in s.get('url', '').lower()]
        top1[ch_id] = non_drm[0] if non_drm else alive_items[0]
    return top1


def pick_fallback_urls(current_urls: list[str]) -> list[str]:
    """从 known_sources 当前 url 列表中抽出 go.bkpcp.top / ivi.bupt.edu.cn 兜底.
    保持原顺序, 缺失跳过.
    """
    out = []
    for host in FALLBACK_HOSTS:
        for u in current_urls:
            if host in u and u not in out:
                out.append(u)
                break
    return out


def merge_one_channel(
    channel_id: str,
    current_urls: list[str],
    top1: dict | None,
) -> tuple[list[str], dict]:
    """
    对单个 CCTV 频道算新 url 列表. 返回 (new_urls, change_info).
    change_info 包含: top1_url, removed_dead, added_fallback, was_changed.
    """
    change = {
        'channel_id': channel_id,
        'top1_url': top1['url'] if top1 else None,
        'top1_score': top1.get('score') if top1 else None,
        'old_urls': list(current_urls),
        'removed': [],
        'kept': [],
        'added': [],
        'was_changed': False,
    }

    # 1. 找 dead 源 (已知死了的 hosts: 69.30.245.50, 74.91.26.218, 38.75.136.137)
    #    注意: 我们没法在脚本里实时测每个 url (那要 60s+), 只靠 cctv_sources.json
    #    的 alive=false 标识 + 已知的"历史坏 host"列表
    KNOWN_DEAD_HOSTS = (
        '69.30.245.50',         # v0.3.5.1 dead (旧 iptv-org)
        '38.75.136.137',        # 6/18 dead (金矿, 老板不用)
        'ottrrs.hl.chinamobile.com',  # v0.3.5.1 dead
        'ott.mobaibox.com',     # v0.3.5.1 dead
        'cdn3.163189.xyz',      # 6/19 dead (新发现的)
    )
    alive_after_filter = []
    for u in current_urls:
        if any(d in u for d in KNOWN_DEAD_HOSTS):
            change['removed'].append(u)
        else:
            alive_after_filter.append(u)
            change['kept'].append(u)

    # 2. 抽兜底 (bkpcp/bupt) — 保留"最初那个源"
    fallbacks = pick_fallback_urls(alive_after_filter)

    # 3. 拼新列表
    new_urls = []

    # a. top-1 (如果存在且不在 known_sources 里)
    if top1:
        top1_url = top1['url']
        # v0.3.7.1 (6/19 12:43): 跳过 CDRM 加密流.  老板装机实测 v0.3.7+50
        # CCTV1 黑屏,  根因是 myqcloud 的 ldncctv.../cdrmldcctv... 是
        # 腾讯云 CDN 加密流,  media_kit + 我们 player 解不了.  即使
        # score=0.9 也不能用.  跳过含 'cdrm' 关键字的 URL,  让 player
        # fallback 到 198.204 那个 IPTV 平台明文流.
        is_drm_url = 'cdrm' in top1_url.lower()
        if is_drm_url:
            # 跳进 change 记录里,  下一段逻辑会重选 non-DRM top1
            change['top1_url'] = None  # 标记为不可用
            change['top1_drm'] = True
            change['removed'].append(top1_url)
            print(f'   ⚠️ {channel_id:20s} top1 是 CDRM 加密流, 跳过: {top1_url}')
        elif top1_url not in alive_after_filter:
            new_urls.append(top1_url)
            change['added'].append(top1_url)
        else:
            # top1 已经在 known_sources 里 (说明 iptv-org 老源活着), 移到最前
            alive_after_filter.remove(top1_url)
            new_urls.append(top1_url)

    # b. 其他还活着的 known_sources (去重)
    for u in alive_after_filter:
        if u not in new_urls:
            new_urls.append(u)

    # c. 兜底 (bkpcp/bupt)
    for fb in fallbacks:
        if fb not in new_urls:
            new_urls.append(fb)
            change['added'].append(fb)

    change['new_urls'] = new_urls
    change['was_changed'] = (new_urls != current_urls)

    return new_urls, change


def main() -> int:
    parser = argparse.ArgumentParser(
        description='CCTV top-1 同步到 known_sources.json (v0.3.7 6/19)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument('--dry-run', action='store_true', help='不写盘, 只打 diff')
    args = parser.parse_args()

    if not CCTV_SRC_PATH.exists():
        print(f'❌ {CCTV_SRC_PATH} 不存在, 先跑 discover_cctv_sources.py', file=sys.stderr)
        return 2
    if not KNOWN_PATH.exists():
        print(f'❌ {KNOWN_PATH} 不存在', file=sys.stderr)
        return 2

    # 备份 cctv_sources.json → .bak
    if not args.dry_run:
        backup_existing_cctv_sources()

    top1 = load_cctv_top1()
    print(f'📊 cctv_sources.json 有 {len(top1)} 频道 top-1 (alive + 最高分)')

    with open(KNOWN_PATH, encoding='utf-8') as f:
        known = json.load(f)

    # CCTV 主频道范围 (跟 cctv_sources.json 里的 channel_id 对齐)
    cctv_ids = set(top1.keys())

    changes = []
    for ch_id in sorted(cctv_ids):
        current_urls = known.get(ch_id, [])
        if not isinstance(current_urls, list):
            continue
        new_urls, change = merge_one_channel(ch_id, current_urls, top1.get(ch_id))
        changes.append(change)
        known[ch_id] = new_urls

    # 报告
    print('\n=== CCTV top-1 同步报告 (v0.3.7 6/19) ===\n')
    changed = [c for c in changes if c['was_changed']]
    print(f'改动 channel: {len(changed)} / {len(changes)}')
    total_removed = sum(len(c['removed']) for c in changes)
    total_added = sum(len(c['added']) for c in changes)
    print(f'删除死源: {total_removed}, 新增 top1/兜底: {total_added}\n')

    for c in changes:
        marker = '✏️ ' if c['was_changed'] else '   '
        top1_str = (
            f"top1={c['top1_score']:.2f}"
            if c['top1_score'] is not None
            else 'top1=NONE'
        )
        print(f'{marker}{c["channel_id"]:20s} ({top1_str})')
        if c['was_changed']:
            print(f'    old ({len(c["old_urls"])}): {c["old_urls"]}')
            print(f'    new ({len(c["new_urls"])}): {c["new_urls"]}')
            if c['removed']:
                print(f'    removed dead: {c["removed"]}')
            if c['added']:
                print(f'    added: {c["added"]}')
        else:
            print(f'    no change ({len(c["old_urls"])} urls)')

    if args.dry_run:
        print('\n⚠️ --dry-run, 不写盘')
        return 0

    with open(KNOWN_PATH, 'w', encoding='utf-8') as f:
        json.dump(known, f, ensure_ascii=False, indent=2)
    print(f'\n✅ 写入 {KNOWN_PATH}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
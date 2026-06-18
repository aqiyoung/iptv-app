# scripts/ 维护脚本

## merge_known_sources.py

**目的**: 把 `assets/data/known_sources.json` 里的 URL 合并到 `assets/data/channels_cn.json` 对应 channel 的 `sources` 字段.

**背景 (6/18)**: 老板反馈 CCTV5 + 14 卫视没源. 排查发现 `channels_cn.json` 484 个 channel **所有 `sources: []` 空的**, 真实 URL 在 `known_sources.json` (134 个 key), 没人合并过.

**用法**:
```bash
cd ~/work/projects/iptv-app
python3 scripts/merge_known_sources.py
```

**输出**:
- 原地改写 `assets/data/channels_cn.json` (111KB → ~200KB, 35+ channel 拿到 source)
- 打印 CCTV5 + 卫视 验证 (期望 CCTV5 ≥ 2, 卫视 ≥ 14)
- 失败退出码 1, 方便 CI 接

**幂等**: 已经 `sources: [...]` 非空的 channel 跳过 (skipped_already_has), 可重复跑.

**ID 匹配规则** (按顺序尝试):
1. `ch['id']` (e.g. `CCTV5.cn`)
2. `ch['id'].replace('.cn', '')` (e.g. `CCTV5`)
3. 已知别名: `name == 'CCTV-5'` → `CCTV5`, `name == 'CCTV-5+'` → `CCTV5Plus`
4. 命中后 key = `{pid}.cn` 在 known_sources.json 里找

**何时重跑**:
- `known_sources.json` 有更新 (新增 URL)
- 老板说要再加 CCTV/卫视频道

**不要**:
- 不要手改 `channels_cn.json` 的 `sources` 字段, 跑脚本覆盖
- 不要把生成的 `channels_cn.json` 在 PR 里反复 force-push, 一次性提即可

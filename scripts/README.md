# Scripts

## merge_known_sources.py

把 `assets/data/known_sources.json` 的 source URL 合并进 `assets/data/channels_cn.json` 对应 channel 的 `sources` 字段.

### 跑一次

```bash
python3 scripts/merge_known_sources.py
```

### 输入

- `assets/data/channels_cn.json` (484 channel, sources 大多空)
- `assets/data/known_sources.json` (135 key, 真实 URL)

### 输出

- 合并后的 `assets/data/channels_cn.json`
- 控制台打印合并统计 (CCTV / 卫视 / 其他)

### 匹配规则

1. **直配**: channel `id` == known key (例如 `AnhuiSatelliteTV.cn` / `CCTV5.cn`)
2. **CCTV name alias**: channels_cn `name='CCTV-5'` → known `CCTV5.cn` 之类
   - `name='CCTV-5'` → `CCTV5.cn`
   - `name='CCTV-5+'` → `CCTV5Plus.cn`
   - `name='CCTV-4K'` → `CCTV4K.cn`
   - `name='CCTV-8K'` → `CCTV8K.cn`
   - `name='CCTV-4 Asia'` → `CCTV4Asia.cn`
   - `name='CCTV-WomensFashion'` → `CCTVWomensFashion.cn`

### 写入规则

- `sources` 字段写入 `[{url, type: 'hls'}, ...]`
- 加 `source_updated_at` 字段追踪合并时间 (e.g. `2026-06-18`)

### 历史

- 2026-06-18: P2-2-A 创建 (老板 6/18 10:36 拍板 拆 A+B)

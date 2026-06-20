# Changelog

All notable changes to this project will be documented in this file.

## 0.3.8+125 (2026-06-21)

- **远程频道分类数据** — 新增 `lib/data/remote_channels_source.dart`,
  从 `aqiyoung/iptv-channels-organized` repo 拉 4 大分类 (cctv 44 /
  satellite 52 / local 102 / international 133 = 331 channels).
- `channelsProvider` 重写为远程优先 + 本地 fallback (assets/data/channels_cn.json
  + channels_i18n.json, 198 channels 兑底).
- `main.dart` 启动时 fire-and-forget 预热 `remoteChannelsProvider`, 失败静默.
- 新增 Riverpod providers: `remoteChannelsSourceProvider`,
  `remoteChannelsProvider` (AsyncNotifier), 可手动 `refresh()` 重拉.
- UI 无改动 — 所有 watch `channelsProvider` 自动走远程优先 + fallback 链.

## 0.2.1 (2026-06-17)

- 5 项 UI 优化（状态栏/调试字/displayName/继续观看/分类标题）
- 引入 libmpv native（`media_kit_libs_video` 引入 Android native libmpv.so）
- 频道名自动中文化（iptv-org 英文 → 中文）
- CCTV5 源（`known_sources.json` 公开 m3u8 兑底）
- 状态栏反转 + 首页容器超出 修复
- Android 包名：`com.aqiyoung.iptv_app` → `com.threelive.iptv`（重命名 Kotlin 包 + 目录）

## 0.2.0 (2026-06-16)

- 收藏 + 搜索 + EPG + TV 焦点 + 启动恢复 + APK 打包
- `media_kit` + `media_kit_video` 卡 5 视频播放
- 修 v0.2.0 启动崩 `MediaKit.ensureInitialized must be called`

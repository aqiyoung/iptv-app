# 三页直播 (Sanyelive)

> 极简新中式 IPTV 直播 APP — 家用电视 / 盒子 / 手机 — Flutter 全平台

[![Latest Release](https://img.shields.io/github/v/release/aqiyoung/iptv-app?label=Latest&color=c96442)](https://github.com/aqiyoung/iptv-app/releases/latest)
[![License](https://img.shields.io/github/license/aqiyoung/iptv-app)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.29.3-02569B?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-TV%20%7C%20Phone%20%7C%20Box-3DDC84?logo=android)](https://www.android.com)

四张截图位置 (老板后续补):

| 浅色主题 | 暗色主题 | 全屏播放 | 横屏 |
|:---:|:---:|:---:|:---:|
| 截图占位 | 截图占位 | 截图占位 | 截图占位 |

---

## ✨ 核心特性

### 🎨 双主题 (v0.3.6)
- **浅色** — 米色 (Parchment) + 朱砂橙 (Terracotta) 主色, 衬线标题, 暖色调
- **暗色** — 深棕黑底 + 米色字 + 暖橙主色, 调性跟浅色一致
- **跟随系统 / 浅色 / 深色** — 设置页一键切换 + 持久化 (shared_preferences)
- **强制暗色 widget 适配** (v0.3.6.1) — 17 处硬编码颜色 token 化, 暗色下所有 widget 清晰

### 📺 视频播放
- **media_kit** 跨平台播放 (libmpv) — 真实 HLS 流, 低延迟
- **538 个频道** (v0.3.5+) — CCTV 1-15 + 35 省级卫视 + 地方台 + 体育
- **35 卫视全覆盖** (v0.3.5.1) — 北京/山东/上海/天津/重庆/河北/山西/陕西... 全活
- **CCTV-5 体育** + **CCTV-5+** (v0.3.5.1) — 公开 IPTV 平台 fallback
- **IPv4 强制** (v0.3.5) — `HttpClient.connectionFactory` + `InternetAddress.lookup(IPv4)`, 修 wifi 下 IPv6 timeout
- **P2-2 播放页布局** (v0.3.5) — 手机嵌入布局 (视频 16:9 + 节目卡 + 频道横滑) ↔ 全屏覆盖
- **P3-1 声音修复** (v0.3.3) — 退到首页 / 切频道 / 杀 APP 三场景, 声音立即释放
- **3s 控件隐身** (P0-1) — 重度 IPTV 用户 90% 时间只看视频, 不需要控件抢眼球
- **触屏又显** — 任何 tap 唤醒控件, 3s 再隐

### 🎯 TV / 盒子适配 (P2-1)
- **Leanback 入口** — Android TV / 当贝 / 小米盒子 启动器可见
- **D-pad 焦点系统** — `TvFocus` (Focus + onKeyEvent + GestureDetector + AnimatedScale 1.05)
- **焦点边** — 2px 赤陶橙 (0.6 alpha), 远距离清晰
- **一屏焦点项上限 9** — `TvFocusCap` / `TvFocusCapWrap` / `TvFocusScope` 守卫
- **3 米可视性** — 字号 / 焦点边距 优化

### 🛠 工程化
- **CI 自动 build + release** — push 后 GitHub Actions 自动出 APK (threely 规则: 本地不构建)
- **CI auto-format** — PR 自动 `dart format`, 不绿就 fail
- **P2-2 测试覆盖** — widget test + unit test, 24+ case
- **PR 流程规范** — 改 pubspec bump 单独 commit, 不混代码 commit
- **数据源脚本** — `scripts/merge_known_sources.py` 幂等合并 + 自动补缺 channel
- **健康检查** — `scripts/check_sources.py` exit 0 才能 release
- **后台强制更新** (v0.3.7 即将) — GitHub releases/latest 检测, **P0 critical 强更, P1 可稍后**

---

## 📦 数据源

| 优先级 | 来源 | 覆盖 |
|---|---|---|
| **主** | `38.75.136.137:78` (公开 IPTV 平台) | CCTV 1-15 (12 hd) + 35 卫视 + 真实 HLS 流 |
| **备** | `74.91.26.218:82` (公开 IPTV 平台) | CCTV 1-15 + 8 卫视 + CCTV-5+ |
| **fallback** | `iptv-org/iptv` (M3U) | 全球 10000+ 频道 (大中华地区源不稳定) |
| **频道元数据** | `iptv-org/database` | 频道 logo / 国家 / 语言 |
| **节目表 (EPG)** | `iptv-org/epg` (XMLTV) | 节目时间 / 名称 / 描述 |

**风险提示**: 公开 IPTV 平台 (`38.75.136.137` / `74.91.26.218`) 长期可用性不确定, 当 fallback 优先, 主源失效切回 iptv-org。

---

## 🧱 技术栈

| 层 | 选型 | 说明 |
|---|---|---|
| **UI** | Flutter 3.29.3 (Dart 3.7.2) | Material 3 + 自定义 IptvTheme |
| **状态管理** | Riverpod 2 (`flutter_riverpod`) | `ConsumerWidget` / `Notifier` |
| **路由** | go_router 14 | URL-driven (`/player/:channelId`) |
| **播放** | `media_kit` + `media_kit_video` | libmpv 后端, 跨平台 |
| **HTTP** | `dio` 5 + 自写 `IPv4Client` | 强制 IPv4 修 wifi |
| **持久化** | `shared_preferences` | 主题模式 / 上次频道 / 收藏 |
| **测试** | `flutter_test` + `flutter_lints` | widget test + unit test |

**设计语言**: 新中式 — 暖色调 (Terracotta `#C96442`) — 衬线标题 (Noto Serif SC) — 书籍级行高 1.9 — 8px 圆角

---

## 📲 下载安装

**最新发布**: [v0.3.6.1](https://github.com/aqiyoung/iptv-app/releases/latest)

```bash
# ARM64 设备 (推荐 — 99% 设备, 含 Android TV / 手机 / 盒子)
wget https://github.com/aqiyoung/iptv-app/releases/download/v0.3.6.1/sanyelive-v0.3.6.1-arm64-v8a.apk

# 验证 SHA256
sha256sum sanyelive-v0.3.6.1-arm64-v8a.apk
# 期望: 299d2cfc884b5d142ed3ecfd0fa0fa6169c5793adad4a00a5698b3421f54588e
```

**全部历史 release**: [Releases](https://github.com/aqiyoung/iptv-app/releases)

| 版本 | 关键改动 | 发布日期 (Asia/Shanghai) |
|---|---|---|
| **v0.3.6.1** (Latest) | 暗色 widget 适配 (17 处) + P0 channel fix | 2026-06-18 13:31 |
| v0.3.5.1 | CCTV-5 fallback + 35 卫视全覆盖 + check_sources.py | 2026-06-18 13:22 |
| v0.3.6 | 暗色主题 + 设置页 + 持久化 | 2026-06-18 12:00 |
| v0.3.5 | 538 频道 + 35 卫视 + IPv4 + sports 中文 | 2026-06-18 11:00 |
| v0.3.4 | TV 焦点 7-9 上限 + 高亮 1.05 | 2026-06-18 10:30 |
| v0.3.3 | 声音不释放修复 (P3-1) | 2026-06-18 07:50 |
| v0.3.2 | 手机端播放页嵌入布局 (P2-2) | 2026-06-18 07:19 |
| v0.3.0 / v0.3.1 | 焦点 / 玻璃 / 冷启动 (P1-1 / P0-2) | 2026-06-17 |
| v0.2.x | 数据层 + 主页 + 播放 + 收藏 + 搜索 | 2026-06-16~17 |

**即将发布**:
- **v0.3.5.2** — 全屏 status bar + TopBar 修复 (P1 hotfix)
- **v0.3.7** — 后台强制更新 (P1 feature)
- **v0.3.8** — TV 焦点全页集成 (P2-3, 1-2 周) + OpenClaw ecosystem 集成 (ClawSweeper / telecrawl)

---

## 🗺 路线图

- [x] **v0.1** 仓库脚手架 + iptv-org 数据接入 + 播放
- [x] **v0.2** 设计系统 + 主页 + 分类 + 频道列表 + 收藏 + 搜索
- [x] **v0.3** 手机端播放页 (P2-2) + 声音修复 (P3-1) + TV 焦点 (P2-1) + 538 频道 (P2-2) + 暗色主题 (v0.3.6) + 暗色 widget 适配 (v0.3.6.1)
- [ ] **v0.3.5.2 / v0.3.7** status bar 修复 + 后台强制更新
- [ ] **v0.3.8** TV 焦点全页集成 (P2-3) + OpenClaw ecosystem 集成
- [ ] **v0.4** 启动屏 / R8 瘦身 / EPG 显示 / 收藏改进 / iOS / 平板端
- [ ] **v0.5** 遥控器数字键 (1-9 直跳) / 长列表分页 / 离线缓存

---

## 🏗 架构 (v0.3)

```
lib/
├── core/
│   ├── http/ipv4_client.dart          # 强制 IPv4 修 wifi
│   ├── router/router.dart             # go_router + PlayerRouteObserver
│   ├── theme/colors.dart              # IptvTheme.light() + dark() + 12 token
│   └── tv/tv_focus.dart               # TvFocus + TvFocusGroup + TvFocusCap
├── data/
│   ├── category_zh.dart               # 32 category 英中映射
│   └── models/channel.dart            # Channel / Source / failover
├── features/
│   ├── category/                      # 分类页 (CCTV / 卫视 / 体育)
│   ├── favorites/                     # 收藏页 + service
│   ├── home/                          # 主页 (3 分类卡 + NextChannelsStrip)
│   ├── player/                        # 播放页 (_buildMobile + _buildFullscreenOverlay)
│   ├── search/                        # 搜索页 (FocusableActionDetector 遥控器)
│   ├── settings/                      # 设置页 (主题切换 + 持久化)
│   └── update/                        # [v0.3.7] 强制更新 dialog
├── services/
│   ├── player_service.dart            # 跨页面 player 单例
│   ├── startup_service.dart           # last channel 持久化
│   └── version_checker.dart           # [v0.3.7] GitHub releases/latest 检测
└── main.dart                          # ThemeMode 注入 + runApp
```

---

## 🧪 本地开发

**铁律 (老板立的死命令)**: **不要本地装 Flutter SDK, 不要本地 build APK**。所有 build 走 GitHub Actions, 改代码 → commit → push → CI 跑 → 自动 release。

```bash
# 1. Clone
git clone https://github.com/aqiyoung/iptv-app.git
cd iptv-app

# 2. 安装依赖 (用系统包管理器, 不要下载 Flutter)
flutter pub get

# 3. 跑测试
flutter test

# 4. 跑分析
flutter analyze

# 5. 改代码 → commit → push, CI 自动 build + release
git checkout -b feat/your-feature
git add .
git commit -m "feat: your feature"
git push origin feat/your-feature
# 开 PR, CI 跑 test + analyze, 合并后 main push 触发 release workflow
```

**数据脚本**:
```bash
# 合并已知源 (幂等, 自动补缺 channel)
python3 scripts/merge_known_sources.py

# 健康检查 (release 前必跑)
python3 scripts/check_sources.py
```

---

## 🤝 贡献 / 反馈

- **Issue**: [github.com/aqiyoung/iptv-app/issues](https://github.com/aqiyoung/iptv-app/issues)
- **Discussion**: 老板内部飞书群
- **PR**: 改代码 + 加 test + bump pubspec 单独 commit, 不混代码 commit

---

## 📜 License

MIT — 详见 [LICENSE](LICENSE)

---

## 🙏 致谢

- **[OpenClaw](https://openclaw.ai/)** — Agent runtime + skill ecosystem + Crabfleet 调度
- **[ClawSweeper](https://clawsweeper.bot)** (自部署 fork) — iptv-app weekly issue/PR triage
- **[telecrawl](https://github.com/openclaw/telecrawl)** (自部署) — Telegram 归档根治失联
- **[iptv-org](https://github.com/iptv-org/iptv)** — M3U 频道源 + EPG + 元数据
- **[media_kit](https://github.com/media-kit/media_kit)** — libmpv 跨平台播放
- **threely (Young)** — 设备 / 资金 / 测试 / 决策支持

---

<sub>Built with 🤖 by 小七 (Xiaoqi) — OpenClaw-powered assistant — last updated 2026-06-18</sub>

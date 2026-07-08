---
version: alpha
name: Shijie-design-analysis
description: 极简新中式设计系统。暖米色宣纸底版 + 赤陶主色，衬线 Georgia 大标题 + 无衬线正文，家用电视/盒子/手机三端适配。暗色模式保留"宣纸/赤陶"调性，不走纯黑灰。

colors:
  # ———— 浅色主题 ————
  surface-light: "#F5F4ED"
  surface-light-card: "#FFFCF6"
  primary: "#E5473A"
  primary-active: "#B83A2A"
  primary-disabled: "#F0B8A8"
  ink: "#2A2520"
  ink-soft: "#6B5F54"
  hairline: "#E8E0D4"
  # ———— 暗色主题 ————
  surface-dark: "#1A1612"
  surface-dark-card: "#25201B"
  surface-dark-card-high: "#312B25"
  ink-dark: "#EDE4D3"
  ink-dark-soft: "#B5A99A"
  hairline-dark: "#3A332C"
  # ———— 共用 ————
  accent: "#E53935"
  accent-focus: "#E24A1A"
  accent-splash: "#F0B429"
  on-primary: "#FFFFFF"

typography:
  serif-headline:
    fontFamily: "Georgia, serif"
    fontSize: 28px
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: 0.5px
  serif-title:
    fontFamily: "Georgia, serif"
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.35
  sans-title:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  caption:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.4
  # ———— TV 焦点放大 ————
  tv-card-title:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: 13px
    fontWeight: 700
    lineHeight: 1.2
  tv-card-meta:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: 10px
    fontWeight: 400
    lineHeight: 1.3
  tv-card-badge:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: 11px
    fontWeight: 700
    lineHeight: 1.2

rounded:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 22px
  pill: 9999px
  full: 9999px

spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 20px
  xl: 24px
  xxl: 32px
  section: 48px

components:
  tv-focus-wrapper:
    transformScale: 1.05
    borderWidth: 2px
    borderColor: "{colors.primary}"
    borderOpacity: 0.6
    animationDurationMs: 150
    animationCurve: ease
    borderRadius: "{rounded.md}"
  tv-card:
    width: 180px
    height: 260px
    borderRadius: "{rounded.sm}"
    padding: 0
    posterAspectRatio: "2:3"
    badgeBorderRadius: "{rounded.xs}"
    infoPadding: 4px 8px
  glass-container:
    blurSigma: 12px
    borderColor: "rgba(255,255,255,0.12)"
    borderWidth: 1px
    borderRadius: "{rounded.md}"
    hoverScale: 1.03
    hoverDuration: 200ms
  category-card:
    borderRadius: "{rounded.md}"
    iconSize: 28
    labelFontSize: 13px
    labelFontWeight: 600
  poster-card:
    borderRadius: "{rounded.sm}"
    titleFontFamily: "Georgia, serif"
    titleFontSize: 18px
    enTitleFontSize: 11px
    badgeFontSize: 10px
    badgeFontWeight: 700
    gradientOverlayHeight: "bottom 40%"
  splash-screen:
    backgroundColor: "{colors.surface-dark}"
    accentLineColor: "{colors.primary}"
    accentLineHeight: 3px
    durationMs: 2500
  search-bar:
    borderRadius: "{rounded.pill}"
    backgroundColor: "rgba(255,255,255,0.08)"
    height: 38px
    padding: "12px 16px"
    iconColor: "{colors.ink-dark-soft}"

---

## 设计哲学

"视界"的设计语言根植于 **新中式极简**——不玩极客霓虹风，也不用拟物化沉重感，走的是"古籍店暖灯下翻书"的质感。

### 核心原则

1. **暖色调优先** — 所有主题色都往暖走。浅色用宣纸米，暗色用古纸焚（深棕黑），主色选赤陶（朱砂替换色）。再不碰 Material 默认的蓝灰/灰绿。
2. **衬线做头，无衬线做身** — 章节大标题用 Georgia 衬线（自带优雅厚重），正文/小标题用系统无衬线（清晰可读）。不手写字体包。
3. **TV 端另有一套交互逻辑** — 遥控器焦点用 1.05 scale + 2px 赤陶边（比默认焦点环更明显但不刺眼）。手机端 tap 直接响应，无焦点态。
4. **玻璃拟态作为功能栈层** — 只有浮层（播放页 NowNext、SourcePicker 等）用玻璃效果（blur 12px + 半透白边）。主页卡片不上玻璃（背景不是视频，blur 无意义）。
5. **暗色不彻底暗** — 暗色页面保留暖调（深棕黑底 + 米色字），不是#000。赤陶主色在暗底上保持橙红对比。

### 暗色 vs 浅色

| 属性 | 浅色 | 暗色 |
|------|------|------|
| 主背景 | `{colors.surface-light}` #F5F4ED 宣纸米 | `{colors.surface-dark}` #1A1612 古纸焚 |
| 卡片 | `{colors.surface-light-card}` #FFFCF6 | `{colors.surface-dark-card}` #25201B |
| 主文字 | `{colors.ink}` #2A2520 深棕 | `{colors.ink-dark}` #EDE4D3 米色 |
| 次文字 | `{colors.ink-soft}` #6B5F54 浅棕 | `{colors.ink-dark-soft}` #B5A99A 暖灰 |
| 分隔线 | `{colors.hairline}` #E8E0D4 | `{colors.hairline-dark}` #3A332C |
| 状态栏 | 黑图标（Brightness.dark） | 白图标（Brightness.light） |

---

## Overview

**产品**：视界（Shijie） — 一款面向家用电视/盒子/手机的直播+影视综合平台。

**核心场景**：
- TV 端：遥控器十字键导航，焦点态 1.05 scale + 赤陶边，自动打开上次播放频道
- 手机端：触控滑动 + tap 交互，标准 Material 手势
- 双端统一：底部导航 + 频道列表 + 播放页 UI 布局一致

**设计资产**：
- 字体：Georgia（衬线大标题，系统自带，无需打包）
- 字体：Roboto（正文，Android 默认无衬线）
- 字体色：跟随 Theme.textTheme.apply()，浅色深棕/暗色米白
- 图标：Material Icons（`Icons.xxx_rounded` 圆角系列）
- 海报图片：网络 URL，2:3 竖版
- 频道 logo：网络 URL，方形/横向

---

## Colors

### Brand & Accent

| Token | 值 | 用途 |
|-------|-----|------|
| `{colors.primary}` | `#E5473A` | 赤陶主色 — CTA 按钮、焦点环、激活态 |
| `{colors.primary-active}` | `#B83A2A` | 紫砂 — 按钮按下态、焦点环深版 |
| `{colors.accent}` | `#E53935` | 红色徽标 — "直播中"标签、错误态 |
| `{colors.accent-focus}` | `#E24A1A` | 朱砂 — TV 焦点环专用（比 primary 略暖） |
| `{colors.accent-splash}` | `#F0B429` | 琥珀 — 启动屏强调线 |

### Surface

| Token | 浅色 | 暗色 |
|-------|------|------|
| Main | `{colors.surface-light}` #F5F4ED | `{colors.surface-dark}` #1A1612 |
| Card | `{colors.surface-light-card}` #FFFCF6 | `{colors.surface-dark-card}` #25201B |
| Card elevated | 同 card | `{colors.surface-dark-card-high}` #312B25 |

### Text

| Token | 浅色 | 暗色 |
|-------|------|------|
| Primary | `{colors.ink}` #2A2520 深棕 | `{colors.ink-dark}` #EDE4D3 米色 |
| Secondary | `{colors.ink-soft}` #6B5F54 浅棕 | `{colors.ink-dark-soft}` #B5A99A 暖灰 |
| On primary | `{colors.on-primary}` #FFFFFF | `{colors.on-primary}` #FFFFFF |

### Semantic

- **Red**: `{colors.accent}` #E53935 — "直播中"badge、加载失败、错误 toast
- **Amber**: `{colors.accent-splash}` #F0B429 — 启动屏加载条、收藏/点赞态
- **White** 70%: `Color(0xB2FFFFFF)` — 海报页频道 logo placeholder
- **White** 85%: `Color(0xD9FFFFFF)` — 播放页覆盖层背景
- **Black** transparent: `Colors.black.withValues(alpha: 0.85)` — 播放页进度条/频道切换浮层

---

## Typography

### Font Family

- **Display / Headlines** — Georgia（serif），系统自带，iOS/Android 均有。用于章节标题和卡片标题。
- **Body / Labels** — Roboto（sans-serif），Android 默认无衬线。用于正文、按钮、标签。
- **Code / Mono** — 无需。项目不含代码展示。

### Hierarchy

| Name | Family | Size | Weight | Line H | Tracking | Use |
|------|--------|------|--------|--------|----------|-----|
| serif-headline | Georgia | 28px | 700 | 1.3 | 0.5px | Section 大标题（首页分类、"电视剧推荐"、"直播回放"） |
| serif-title | Georgia | 20px | 600 | 1.35 | 0 | AppBar 标题、弹窗标题 |
| sans-title | Roboto | 16px | 600 | 1.4 | 0 | 子标题、卡片标题 |
| body | Roboto | 14px | 400 | 1.5 | 0 | 正文、频道名、源列表 |
| caption | Roboto | 12px | 400 | 1.4 | 0 | 副文字、时间戳、版权信息 |
| tv-card-title | Roboto | 13px | 700 | 1.2 | 0 | TV 端频道卡片标题（TV 端字号比手机端略小） |
| tv-card-meta | Roboto | 10px | 400 | 1.3 | 0 | TV 端卡片元数据（EPG 时间、分辨率） |
| tv-card-badge | Roboto | 11px | 700 | 1.2 | 0 | TV 端"直播中"/"4K"标签 |

### Color Strategy

Text colors follow the theme — **never hardcode** a text color on a `TextStyle` that will be rendered under both light and dark themes. Use `Theme.of(context).colorScheme.onSurface` / `onSurfaceVariant` or let the `TextTheme.apply()` pipeline handle it.

Exception: overlay text over a known-dark surface (e.g., poster wall dark background, player page overlay) — use explicit white or white-70%.

### Principles

- **Georgia serif is the signature.** If something is a section heading, it should use serif-headline or serif-title. It's the one thing that makes the brand recognizable.
- **No bold body text.** Body text is always 400. Bold is reserved for titles and labels.
- **No font package imports.** We use system fonts (Georgia + Roboto). Reduces APK size and startup time.
- **TV card title is 13px bold** — smaller than phone body, but readable at TV viewing distance.

---

## Layout

### Spacing System

- **Base unit**: 4px.
- **Tokens**: `{spacing.xxs}` 4px · `{spacing.xs}` 8px · `{spacing.sm}` 12px · `{spacing.md}` 16px · `{spacing.lg}` 20px · `{spacing.xl}` 24px · `{spacing.xxl}` 32px · `{spacing.section}` 48px.
- **Content padding**: `{spacing.md}` (16px) horizontally for most pages — poster wall, settings, search, VOD browser.
- **Section margin**: `{spacing.section}` (48px) between major page sections.
- **Card internal padding**: `{spacing.sm}` to `{spacing.md}` (12-16px) for TV cards; `{spacing.xxl}` (32px) for settings page sections.

### TV End Specific

- **Poster wall horizontal padding**: 16px (with MediaQuery top padding for status bar).
- **Channel strip spacing**: 14px between items.
- **Focus animation**: scale 1.0 → 1.05, 150ms ease.
- **Card spacing (grid)**: 12px vertical gap; horizontal gap handled by padding + flexible sizing.

---

## Elevation & Depth

| Level | Treatment | Use |
|-------|-----------|-----|
| Flat | No shadow, no border | Body sections, main background |
| Hairline | 1px `{colors.hairline}` or `{colors.hairline-dark}` | Dividers, card outlines |
| Glass | blur(12px) + 1px rgba(255,255,255,0.12) border | Player overlay panels (NowNext, SourcePicker) |
| Overlay dark | `Colors.black.withValues(alpha: 0.85)` background | Player bottom bars |
| TV Focus | scale(1.05) + 2px `{colors.primary}` @ 60% | TV card hover/focus |

### Glass Philosophy

Glass (blur + semi-transparent border) is **only used over video content** in the player page. The blur reveals moving video behind, producing a satisfying floating effect. On the home page (solid parchment/dark background), glass adds no value — use flat cards instead. This avoids the "bad Android blur" problem where blur on a static background just looks like a gray box.

---

## Shapes

| Token | Value | Use |
|-------|-------|-----|
| `{rounded.xs}` | 4px | Small badge, player progress bar knob |
| `{rounded.sm}` | 8px | TV channel cards, poster cards, search bar, buttons |
| `{rounded.md}` | 12px | Glass container, focus ring radius, category cards |
| `{rounded.lg}` | 16px | Settings page sections, large cards |
| `{rounded.xl}` | 22px | Poster wall "现在直播" tab button |
| `{rounded.pill}` | 9999px | Search bar, badge pills |

---

## Components

### Top Navigation (AppBar)

- **Background**: `{colors.surface-light}` (light) / `{colors.surface-dark}` (dark) — flush with scaffold background, no elevation.
- **Title**: `{typography.serif-title}` — Georgia 20px 600.
- **System overlay**: Status bar icons — black on light, white on dark. Navigation bar same as scaffold.
- **Height**: Standard Material AppBar (56dp or 64dp with padding).

### Buttons

**`button-primary`** — The signature terracotta CTA.
- Background `{colors.primary}` (#E5473A), text `{colors.on-primary}` (white).
- Type `{typography.sans-title}` (Roboto 16px 600) or `{typography.body}` (14px) depending on context.
- Rounded `{rounded.sm}` (8px).

**`button-secondary`** — Transparent with hairline.
- Background transparent, text color from theme.
- 1px hairline border from `{colors.hairline}` / `{colors.hairline-dark}`.
- Same padding and radius as primary.

**`text-link`** — Inline link in primary color.
- No background, no underline by default.
- Used for "设置" links, "查看更多".

### Cards

**`tv-channel-card`** — The most common card, used for channel grid on TV.
- **Width**: 180px. **Height**: 260px. **Border radius**: `{rounded.sm}` (8px).
- **Poster**: 2:3 aspect ratio image loaded from network URL.
- **Title**: `{typography.tv-card-title}` (13px 700), max 1 line, ellipsis overflow.
- **Meta line**: `{typography.tv-card-meta}` (10px 400) for EPG show title.
- **Badge**: "直播中" badge in `{colors.accent}` (#E53935), rounded `{rounded.xs}` (4px), top-left positioned.
- **Hover (TV)**: `{component.tv-focus-wrapper}` — scale 1.05 + 2px primary border at 60% opacity.
- **Background**: card color from theme (`surface-light-card` / `surface-dark-card` on the poster wall, transparent in channel strip).

**`poster-card`** — Landing page hero poster.
- Border radius `{rounded.sm}` (8px).
- Title in Georgia 18px, en title in 11px.
- Gradient overlay at bottom 40%.
- Paging via PageView with dot indicators.

**`category-card`** — Category grid item (电影/电视剧/综艺/动漫等).
- Border radius `{rounded.md}` (12px).
- Icon size 28, label 13px 600.
- Background: single Color, not gradient.
- Used in horizontal scrollable row on landing page.

**`glass-container`** — Player overlay panel.
- Blur: sigma 12 (10-15 range). Border: 1px white at 12% opacity.
- Border radius `{rounded.md}` (12px).
- Hover (TV): scale 1.03, 200ms ease.
- Used for: NowNextProgram, NextChannelsStrip, SourcePickerSheet.

### Inputs & Forms

- **Search bar**: pill shape `{rounded.pill}`, 38px height, background rgba(255,255,255,0.08) on dark surfaces, icon in `{colors.ink-dark-soft}`.
- **Settings page**: `{spacing.xxl}` (32px) internal padding for sections, `{rounded.lg}` (16px) for section containers. List tiles with switch/trailing widgets.
- **Source picker**: expanded bottom sheet, `{rounded.md}` (12px) top corners.

### Badges / Tags

| Badge | Style | Use |
|-------|-------|-----|
| "直播中" | `{colors.accent}` bg, white text, `{rounded.xs}` | Active channel indicator |
| "4K" / "超清" | White text on dark bg, `{rounded.pill}` | Resolution indicator |
| "NEW" | Terracotta bg or amber text | New content flag (not yet in active use) |
| Session dot | 6px circle, primary color | Bottom nav active page indicator |

### Search

- **Bar**: pill-shaped search bar with search icon, hint text "搜索频道或节目", clear-on-escape.
- **Results**: list of channels and VOD titles, each with icon + title + subtitle.
- **TV focus**: full TvFocus wrapper on result items.
- **Empty state**: centered icon + "没有找到结果" text.

---

## Motion & Animation

| Element | Duration | Easing | Detail |
|---------|----------|--------|--------|
| TV focus scale | 150ms | ease | 1.0 → 1.05 |
| Poster wall page switch | 300ms | easeInOut | PageView scroll |
| Glass hover scale | 200ms | ease | 1.0 → 1.03 |
| Splash screen | 2500ms | — | Logo fade-in + amber line grow |
| Channel switching | short | instant | No animation on EPG data swap |
| Fade transition | 300ms | easeInOut | Page-to-page transitions |

### Splash Screen

1. Dark background `{colors.surface-dark}`.
2. "视界" brand logo (Georgia serif in `{colors.ink-dark}`) fades in.
3. An amber accent line `{colors.accent-splash}` animates from center, width 0 → full, height 3px.
4. Total duration ~2500ms.
5. Auto-navigates to home page after timeout.

---

## Poster Wall (Landing Page)

The landing page is a vertically scrollable wall of content with these sections:

1. **Top bar**: Brand logo (`"视界"` in serif) + settings gear icon.
2. **Live tab preview**: The currently playing channel card (large, with "直播中" badge, EPG info).
3. **Hero posters**: PageView with 4 scrolling posters (庆余年/三体/漫长的季节/狂飙) + dot indicators.
4. **Category shortcuts**: Horizontal scrollable row (电视直播/电影/电视剧/综艺/动漫/纪录片/体育).
5. **Channel browser (VOD)**: Grid of poster cards sorted by category, lazy-loaded.

---

## Dark Theme Rules

- **Never use pure black** (#000) for backgrounds. Use `{colors.surface-dark}` (#1A1612).
- **Never use pure white** with full opacity on dark. Text uses `{colors.ink-dark}` (#EDE4D3).
- **Status bar icons must be white** on dark (Brightness.light).
- **Navigation bar** dark background with white icons (`Brightness.light`).
- **Poster wall** (#101010) is slightly darker than regular dark surface for visual distinction.

---

## Responsive Behavior

### Breakpoints

| Device | Orientation | Behavior |
|--------|------------|----------|
| TV (720p/1080p) | Landscape | Full poster wall grid, focus-driven navigation, 180px cards |
| Phone | Portrait | Mobile layout, touch-driven, bottom nav bar |
| Tablet | Landscape/Portrait | Same as TV layout on landscape, phone layout on portrait |

### TV vs Phone Differences

| Aspect | TV | Phone |
|--------|----|-------|
| Navigation | D-pad + remote | Bottom nav + tab bar |
| Card layout | Grid (2-3 columns) | List or single column grid |
| Focus system | TvFocus (scale + border) | Tap only |
| Channel strip | Horizontal scrollable row | Horizontal scrollable row (same) |
| Settings | Same layout, larger touch targets | Same layout, scrollable |

### Touch Targets (Phone)

- Min touch target: 48dp (Material spec).
- Channel cards: tap to play.
- Category shortcuts: tap to navigate.
- Source picker: drag up sheet.

---

## Do's and Don'ts

### Do

- ✅ **Use Georgia serif for all section headings.** It's the brand signature.
- ✅ **Prefer warm tones.** Even on dark mode, lean into warm browns, not neutral grays.
- ✅ **Keep cards flat on home page.** Glass effect only on player overlay.
- ✅ **Use accent-terracotta for focused/highlighted states.** Not the default Material blue.
- ✅ **Text color must follow theme.** Never hardcode text color in TextStyle used across themes.
- ✅ **Use Material Icons rounded variant** (`Icons.xxx_rounded`) for consistent visual weight.
- ✅ **Maintain 16px horizontal padding across all pages** for visual consistency.
- ✅ **Show "直播中" badge on currently-playing channel** in red for discoverability.

### Don't

- ❌ **Don't use Material default blue/slate palette.** Replace with terracotta + warm brown.
- ❌ **Don't use pure black backgrounds.** Always use `{colors.surface-dark}` (#1A1612).
- ❌ **Don't apply glass blur on solid backgrounds.** It looks muddy.
- ❌ **Don't hardcode text colors** — always use `Theme.of(context).colorScheme.onSurface`.
- ❌ **Don't use font-weight 300 (light) anywhere.** Legibility on TV matters.
- ❌ **Don't use shadows for card elevation.** Use color contrast (surface-card vs surface).
- ❌ **Don't add font packages.** Georgia + Roboto are sufficient.
- ❌ **Don't use horizontal scroll for categories on phone** (overflow categories to a full-page grid instead).

---

## Known Gaps

- **No loading skeleton**: Currently shows loading text/indicator. Future: implement shimmer skeleton matching brand palette.
- **No pull-to-refresh**: Channel list uses auto-refresh on app open. No manual pull gesture yet.
- **No custom font animation**: Georgia headline uses system font only. No variable font animation.
- **No branding illustration system**: Hero banners use poster art; no custom illustrations yet.
- **No icon set**: Uses Material Icons only. No custom SVG icons.
- **No error state illustration**: Errors show text only, no branded empty state graphic.
- **No image fallback gradient**: Poster loading uses empty icon; consider branded gradient placeholder.
- **No transition animation between pages**: Page switches are instant. Consider fade transitions.
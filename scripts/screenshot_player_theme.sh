#!/bin/bash
# v0.3.5.8: 4 截图脚本 — 验证 player_page theme 适配 (浅色 + 深色)
# 截图: 1) light 播放页 2) dark 播放页 3) light 全屏 4) dark 全屏
# 依赖: adb + emulator 运行中
# 输出: scripts/screenshots_player_theme/

set -euo pipefail

OUT_DIR="scripts/screenshots_player_theme"
mkdir -p "$OUT_DIR"

PKG="com.threelive.tv"
ACT="com.threelive.tv.MainActivity"

echo "=== 截图 1: light theme 播放页 ==="
adb shell am start -n "$ACT" -a android.intent.action.VIEW -d "sanyelive://player/CCTV1.cn" 2>/dev/null || true
sleep 3
adb exec-out screencap -p > "$OUT_DIR/1_light_player.png" && echo "OK: $OUT_DIR/1_light_player.png"

echo "=== 截图 2: dark theme 播放页 (需手动切深色) ==="
echo "请手动在设置页切到深色主题, 然后按回车..."
read -r
adb exec-out screencap -p > "$OUT_DIR/2_dark_player.png" && echo "OK: $OUT_DIR/2_dark_player.png"

echo "=== 截图 3: light theme 全屏 (点视频区全屏) ==="
echo "请手动点视频区进入全屏, 然后按回车..."
read -r
adb exec-out screencap -p > "$OUT_DIR/3_light_fullscreen.png" && echo "OK: $OUT_DIR/3_light_fullscreen.png"

echo "=== 截图 4: dark theme 全屏 ==="
echo "请手动退出全屏再进入, 然后按回车..."
read -r
adb exec-out screencap -p > "$OUT_DIR/4_dark_fullscreen.png" && echo "OK: $OUT_DIR/4_dark_fullscreen.png"

echo "=== 4 截图完成 ==="
ls -la "$OUT_DIR/"

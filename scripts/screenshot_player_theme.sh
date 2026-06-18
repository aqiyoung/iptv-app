#!/bin/bash
# v0.3.5.7: 4 截图 — player_page 浅色/暗色/全屏/横屏
# 用法: ./scripts/screenshot_player_theme.sh <device_id>
# 输出: screenshots/ 目录

set -euo pipefail

DEVICE="${1:?用法: $0 <device_id>}"
OUTDIR="screenshots"
mkdir -p "$OUTDIR"

echo "📸 v0.3.5.7 player_page 主题截图"
echo "   device: $DEVICE"

# 确保在 player 页面 (通过 deep link 或 UI 导航)
echo "Step 1: 进播放页 (浅色主题假设当前是 light mode)"
adb -s "$DEVICE" shell am start -a android.intent.action.VIEW \
  -d "sanyelive://player/CCTV1.cn" 2>/dev/null || true
sleep 3

echo "Step 2: 浅色主题截图"
adb -s "$DEVICE" exec-out screencap -p > "$OUTDIR/01_light_theme.png"
echo "  ✅ 01_light_theme.png"

echo "Step 3: 点全屏按钮"
# 全屏按钮在右下角 (约 90% right, 85% bottom of 16:9 area)
adb -s "$DEVICE" shell input tap 1000 500
sleep 2

echo "Step 4: 全屏截图"
adb -s "$DEVICE" exec-out screencap -p > "$OUTDIR/02_fullscreen.png"
echo "  ✅ 02_fullscreen.png"

echo "Step 5: 退出全屏 (点退出按钮)"
adb -s "$DEVICE" shell input tap 100 100
sleep 2

echo "Step 6: 切到暗色主题 (需要系统暗色模式)"
adb -s "$DEVICE" shell cmd uimode night yes 2>/dev/null || \
  adb -s "$DEVICE" shell settings put secure ui_night_mode 2 2>/dev/null || true
sleep 2

echo "Step 7: 重启播放页 (暗色)"
adb -s "$DEVICE" shell am force-stop com.sanyelive.app 2>/dev/null || true
sleep 1
adb -s "$DEVICE" shell am start -a android.intent.action.VIEW \
  -d "sanyelive://player/CCTV1.cn" 2>/dev/null || true
sleep 3

echo "Step 8: 暗色主题截图"
adb -s "$DEVICE" exec-out screencap -p > "$OUTDIR/03_dark_theme.png"
echo "  ✅ 03_dark_theme.png"

echo "Step 9: 暗色 + 全屏"
adb -s "$DEVICE" shell input tap 1000 500
sleep 2
adb -s "$DEVICE" exec-out screencap -p > "$OUTDIR/04_dark_fullscreen.png"
echo "  ✅ 04_dark_fullscreen.png"

# 还原浅色主题
adb -s "$DEVICE" shell cmd uimode night no 2>/dev/null || \
  adb -s "$DEVICE" shell settings put secure ui_night_mode 1 2>/dev/null || true

echo ""
echo "✅ 4 截图完成:"
ls -la "$OUTDIR"/{01_light_theme,02_fullscreen,03_dark_theme,04_dark_fullscreen}.png

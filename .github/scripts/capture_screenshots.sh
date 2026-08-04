#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Captures Play Store screenshots from a real emulator running the real APK.
# Taps each bottom-nav destination and screencaps it.
# Nav has 6 items, so each sits at (width/12)*(2i+1) horizontally.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

PKG="com.splashstars.focusly"
OUT="screenshots"
mkdir -p "$OUT"

echo "Waiting for device..."
adb wait-for-device
adb shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done'
sleep 5

# Keep the screen on and unlocked
adb shell svc power stayon true
adb shell input keyevent 82 || true

echo "Installing APK..."
adb install -r -t focusly/build/app/outputs/flutter-apk/app-debug.apk

# Grant notification permission so no system dialog covers the UI
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

echo "Launching app..."
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 12   # allow Flutter first frame + DB seed

# Dismiss any runtime permission dialog that still appeared
adb shell input keyevent 4 2>/dev/null || true
sleep 2

# Screen geometry
SIZE=$(adb shell wm size | tr -d '\r' | awk -F': ' '{print $2}')
W=$(echo "$SIZE" | cut -dx -f1)
H=$(echo "$SIZE" | cut -dx -f2)
echo "Screen: ${W}x${H}"

# Bottom nav sits just above the system nav bar
NAV_Y=$(( H * 92 / 100 ))

shot () {  # shot <index> <name>
  local i=$1 name=$2
  local x=$(( W * (2*i + 1) / 12 ))
  echo "  tab $i -> tapping ($x,$NAV_Y) for $name"
  adb shell input tap "$x" "$NAV_Y"
  sleep 4
  adb exec-out screencap -p > "$OUT/$(printf '%02d' $((i+1)))_${name}.png"
}

# Home first (already showing) then each destination
adb exec-out screencap -p > "$OUT/01_home.png"
shot 1 tasks
shot 2 focus
shot 3 planner
shot 4 habits
shot 5 stats

# Extra: start a focus session so the timer screenshot shows it running
adb shell input tap $(( W * 5 / 12 )) "$NAV_Y"   # back to Focus tab
sleep 3
adb shell input tap $(( W / 3 )) $(( H * 72 / 100 ))   # Start button
sleep 5
adb exec-out screencap -p > "$OUT/07_focus_running.png"

echo "Captured:"
ls -la "$OUT"
for f in "$OUT"/*.png; do
  echo "$f -> $(stat -c%s "$f") bytes"
done

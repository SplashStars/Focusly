#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Captures Play Store screenshots from a real emulator running the real APK.
#
# CI emulators frequently throw "Pixel Launcher isn't responding" ANR dialogs
# which sit on top of the app and swallow taps, so every step defensively
# dismisses dialogs and re-foregrounds the app before capturing.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

PKG="com.splashstars.focusly"
OUT="screenshots"
mkdir -p "$OUT"

adb wait-for-device
adb shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done'
sleep 5

# Reduce the chance of ANR / crash dialogs appearing at all
adb shell svc power stayon true
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
adb shell settings put secure immersive_mode_confirmations confirmed
adb shell settings put global anr_show_background 0 2>/dev/null || true
adb shell settings put global send_action_app_error 0 2>/dev/null || true
adb shell input keyevent 82 || true

echo "Installing APK..."
adb install -r -t focusly/build/app/outputs/flutter-apk/app-debug.apk
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

W=$(adb shell wm size | tr -d '\r' | awk -F': ' '{print $2}' | cut -dx -f1)
H=$(adb shell wm size | tr -d '\r' | awk -F': ' '{print $2}' | cut -dx -f2)
echo "Screen: ${W}x${H}"
NAV_Y=$(( H * 94 / 100 ))

# ── Dismiss any system dialog ("isn't responding", "has stopped", etc.) ──────
dismiss_dialogs () {
  for _ in 1 2 3; do
    local dump
    dump=$(adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb shell cat /sdcard/ui.xml 2>/dev/null)
    if echo "$dump" | grep -qi "isn't responding\|has stopped\|keeps stopping\|close app"; then
      echo "  ! system dialog detected - dismissing"
      # Prefer "Wait" so the launcher is not killed; fall back to BACK
      local bounds
      bounds=$(echo "$dump" | tr '>' '\n' | grep -i 'text="Wait"' | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | head -1)
      if [ -n "$bounds" ]; then
        local coords x1 y1 x2 y2
        coords=$(echo "$bounds" | grep -o '[0-9]\+')
        x1=$(echo "$coords" | sed -n 1p); y1=$(echo "$coords" | sed -n 2p)
        x2=$(echo "$coords" | sed -n 3p); y2=$(echo "$coords" | sed -n 4p)
        adb shell input tap $(( (x1 + x2) / 2 )) $(( (y1 + y2) / 2 ))
      else
        adb shell input keyevent 4
      fi
      sleep 2
    else
      break
    fi
  done
}

# ── Bring Focusly to the foreground ─────────────────────────────────────────
foreground () {
  local focus
  focus=$(adb shell dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus' || true)
  if ! echo "$focus" | grep -q "$PKG"; then
    adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    sleep 4
  fi
}

echo "Launching app..."
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 14          # Flutter first frame + DB seed
dismiss_dialogs
foreground
sleep 3

shot () {  # shot <navIndex> <name>
  local i=$1 name=$2
  dismiss_dialogs
  foreground
  if [ "$i" -ge 0 ]; then
    local x=$(( W * (2*i + 1) / 12 ))
    echo "  tab $i -> tap ($x,$NAV_Y)  [$name]"
    adb shell input tap "$x" "$NAV_Y"
    sleep 5
    dismiss_dialogs
  fi
  adb exec-out screencap -p > "$OUT/$(printf '%02d' $((i+2)))_${name}.png"
  echo "     saved $(stat -c%s "$OUT/$(printf '%02d' $((i+2)))_${name}.png") bytes"
}

# ── Capture the "to do" states first ────────────────────────────────────────
dismiss_dialogs; foreground
adb exec-out screencap -p > "$OUT/01_home.png"
echo "  saved 01_home.png"

shot 1 tasks      # tasks still outstanding
shot 2 focus
shot 3 planner
shot 4 habits

# ── Generate REAL activity so the Weekly Report is not an empty state ───────
# Tasks complete by swiping right (flutter_slidable), habits toggle by tapping
# the ring. This is genuine app behaviour, not seeded fake history.
echo "Generating real activity for the report..."
dismiss_dialogs; foreground
adb shell input tap $(( W * 3 / 12 )) "$NAV_Y"     # Tasks tab
sleep 4

# task_card uses flutter_slidable with startActionPane extentRatio 0.25 and no
# DismissiblePane: a right swipe only REVEALS a green "Done" button occupying the
# left quarter of the card, which then has to be tapped.
for _ in 1 2; do
  adb shell input swipe $(( W / 4 )) $(( H * 29 / 100 )) $(( W * 6 / 10 )) $(( H * 29 / 100 )) 400
  sleep 2
  adb shell input tap $(( W / 8 )) $(( H * 29 / 100 ))   # tap the revealed "Done"
  sleep 3
  dismiss_dialogs
done

# Complete the habit from the Home screen (tap its progress ring)
adb shell input tap $(( W / 12 )) "$NAV_Y"          # Home tab
sleep 4
adb shell input tap $(( W * 16 / 100 )) $(( H * 695 / 1000 ))
sleep 3
dismiss_dialogs
adb exec-out screencap -p > "$OUT/02_home_progress.png"

shot 5 stats      # now populated with real completions

# Focus tab with a session actually running
dismiss_dialogs; foreground
adb shell input tap $(( W * 5 / 12 )) "$NAV_Y"     # Focus tab
sleep 4
adb shell input tap $(( W / 3 )) $(( H * 66 / 100 ))  # Start button
sleep 6
dismiss_dialogs
adb exec-out screencap -p > "$OUT/08_focus_running.png"

echo ""
echo "=== captured ==="
for f in "$OUT"/*.png; do echo "$(stat -c%s "$f") bytes  $f"; done
echo ""
echo "Distinct images (by md5):"
md5sum "$OUT"/*.png | awk '{print $1}' | sort -u | wc -l

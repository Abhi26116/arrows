#!/usr/bin/env bash
# Records the App Store app previews and encodes them.
#
#   ./tool/app_preview.sh [iphone|ipad]      (default: both)
#
# Plays a real board frame by frame (see tool/app_preview.dart) and encodes the
# result to what the App Store accepts:
#
#   iphone  886x1920   6.5"/6.7" portrait
#   ipad   1200x1600   12.9" portrait
#
# Both are H.264, 30fps, 15-30 seconds. Apple wants an audio track even when
# there is nothing to hear, so a silent one is muxed in.
set -euo pipefail

cd "$(dirname "$0")/.."

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is not installed — brew install ffmpeg" >&2
  exit 1
}

record() {
  local device="$1" out crop frames count
  case "$device" in
    iphone) out=store/preview/app_preview_iphone_6.7.mp4; crop=886:1920 ;;
    ipad)   out=store/preview/app_preview_ipad_12.9.mp4;  crop=1200:1600 ;;
    *) echo "unknown device: $device" >&2; return 1 ;;
  esac

  frames="${TMPDIR:-/tmp}/arrows_preview_${device}"
  rm -rf "$frames"
  mkdir -p "$frames" store/preview

  echo "==> $device: recording frames"
  flutter test tool/app_preview.dart \
    --dart-define=SCREENSHOT_MODE=true \
    --dart-define=DEVICE="$device" \
    --dart-define=FRAMES_DIR="$frames"

  count=$(find "$frames" -name 'frame_*.png' | wc -l | tr -d ' ')
  echo "==> $device: $count frames ($((count / 30))s)"
  if [ "$count" -lt 450 ] || [ "$count" -gt 900 ]; then
    echo "warning: the App Store wants 15-30s, i.e. 450-900 frames" >&2
  fi

  # The render lands a pixel or two off the exact preview size; crop rather
  # than scale so nothing is stretched.
  echo "==> $device: encoding"
  ffmpeg -y -loglevel error -framerate 30 -i "$frames/frame_%04d.png" \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -vf "crop=$crop:0:0" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 -crf 18 \
    -c:a aac -b:a 128k -shortest -movflags +faststart \
    "$out"

  rm -rf "$frames"

  echo "==> $out"
  ffprobe -v error -show_entries format=duration \
    -show_entries stream=codec_name,width,height,r_frame_rate \
    -of default=noprint_wrappers=1 "$out"
  echo
}

if [ $# -eq 0 ]; then
  record iphone
  record ipad
else
  record "$1"
fi

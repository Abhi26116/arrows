#!/usr/bin/env bash
# Records the App Store app preview and encodes it.
#
#   ./tool/app_preview.sh
#
# Plays a real board frame by frame (see tool/app_preview.dart) and encodes the
# result to the size, codec and duration the App Store accepts for a 6.5"/6.7"
# iPhone: 886x1920, H.264, 30fps, 15-30 seconds.
#
# Apple wants an audio track even when there is nothing to hear, so a silent
# one is muxed in.
set -euo pipefail

cd "$(dirname "$0")/.."

FRAMES="${TMPDIR:-/tmp}/arrows_preview_frames"
OUT=store/preview/app_preview_iphone_6.7.mp4

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is not installed — brew install ffmpeg" >&2
  exit 1
}

rm -rf "$FRAMES"
mkdir -p "$FRAMES" store/preview

echo "==> recording frames"
flutter test tool/app_preview.dart \
  --dart-define=SCREENSHOT_MODE=true \
  --dart-define=FRAMES_DIR="$FRAMES"

count=$(find "$FRAMES" -name 'frame_*.png' | wc -l | tr -d ' ')
echo "==> $count frames ($((count / 30))s)"
if [ "$count" -lt 450 ] || [ "$count" -gt 900 ]; then
  echo "warning: the App Store wants 15-30s, i.e. 450-900 frames" >&2
fi

echo "==> encoding"
ffmpeg -y -loglevel error -framerate 30 -i "$FRAMES/frame_%04d.png" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 -crf 18 \
  -c:a aac -b:a 128k -shortest -movflags +faststart \
  "$OUT"

rm -rf "$FRAMES"

echo
echo "==> $OUT"
ffprobe -v error -show_entries format=duration \
  -show_entries stream=codec_name,width,height,r_frame_rate \
  -of default=noprint_wrappers=1 "$OUT"

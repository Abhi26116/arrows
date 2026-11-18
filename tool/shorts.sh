#!/usr/bin/env bash
# Records a YouTube Shorts / Instagram Reels clip of a real board.
#
#   ./tool/shorts.sh <level> <name> "<caption>" ["<end caption>"] [hold-frames]
#
#   level        board id, 1-600
#   name         output file, store/shorts/<name>.mp4
#   caption      shown above the phone for the whole clip (any language)
#   end caption  replaces it for the last 2.5 seconds, after the board clears
#   hold-frames  frames (30 = 1s) to sit on the untouched board before the
#                first tap, for "which arrow goes first?" clips; default 0
#
# Plays the board to the end through the shipping GameScreen (see
# tool/app_preview.dart, DEVICE=shorts) and encodes 1080x1920 H.264 at 30fps
# with a silent audio track, so a trending sound can be added in the app at
# upload time.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -lt 3 ]; then
  sed -n '2,13p' "$0" >&2
  exit 1
fi

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is not installed — brew install ffmpeg" >&2
  exit 1
}

level="$1" name="$2" hook="$3" end="${4:-}" hold="${5:-0}"
out="store/shorts/$name.mp4"
frames="${TMPDIR:-/tmp}/arrows_shorts_$name"
rm -rf "$frames"
mkdir -p "$frames" store/shorts

b64() { printf '%s' "$1" | base64 | tr -d '\n'; }

echo "==> $name: recording level $level"
flutter test tool/app_preview.dart \
  --dart-define=SCREENSHOT_MODE=true \
  --dart-define=DEVICE=shorts \
  --dart-define=FRAMES_DIR="$frames" \
  --dart-define=LEVEL="$level" \
  --dart-define=HOLD_START="$hold" \
  --dart-define=HOOK_B64="$(b64 "$hook")" \
  --dart-define=END_B64="$(b64 "$end")"

count=$(find "$frames" -name 'frame_*.png' | wc -l | tr -d ' ')
echo "==> $name: $count frames ($((count / 30))s)"

echo "==> $name: encoding"
ffmpeg -y -loglevel error -framerate 30 -i "$frames/frame_%04d.png" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -vf "crop=1080:1920:0:0" \
  -c:v libx264 -profile:v high -level 4.1 -pix_fmt yuv420p -r 30 -crf 18 \
  -c:a aac -b:a 128k -shortest -movflags +faststart \
  "$out"

rm -rf "$frames"

echo "==> $out"
ffprobe -v error -show_entries format=duration \
  -show_entries stream=codec_name,width,height \
  -of default=noprint_wrappers=1 "$out"

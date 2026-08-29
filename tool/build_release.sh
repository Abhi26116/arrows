#!/usr/bin/env bash
# Builds the Play Store bundle from this Mac.
#
#   ./tool/build_release.sh [build-number]
#
# Guards against the two mistakes that are easy to make and painful to undo:
# shipping a debug-signed bundle, and shipping one full of test ads.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f android/key.properties ]; then
  cat >&2 <<'MSG'
android/key.properties is missing, so the build would fall back to DEBUG keys
and Play would reject the bundle.

  1. keytool -genkey -v -keystore ~/arrows-release.jks -storetype PKCS12 \
       -keyalg RSA -keysize 2048 -validity 10000 -alias arrows
  2. cp android/key.properties.example android/key.properties
  3. fill in the passwords, alias and storeFile path
MSG
  exit 1
fi

BUILD_NUMBER="${1:-}"
ARGS=(--release --dart-define=LIVE_ADS=true)
if [ -n "$BUILD_NUMBER" ]; then
  ARGS+=(--build-number="$BUILD_NUMBER")
fi

echo "==> flutter build appbundle ${ARGS[*]}"
flutter build appbundle "${ARGS[@]}"

AAB=build/app/outputs/bundle/release/app-release.aab

# /usr/bin/keytool on macOS is a stub that needs a JRE; Android Studio ships a
# real JDK, so prefer that.
KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
if [ ! -x "$KEYTOOL" ]; then
  KEYTOOL="$(command -v keytool || true)"
fi

if [ -n "$KEYTOOL" ]; then
  echo
  echo "==> Signed with:"
  # Reads the certificate out of the bundle — no passwords involved.
  "$KEYTOOL" -printcert -jarfile "$AAB" \
    | grep -E "Owner:|Valid from:|SHA256:" | head -4 || true
fi

echo
echo "==> Bundle: $AAB"
ls -lh "$AAB" | awk '{print "    " $5}'

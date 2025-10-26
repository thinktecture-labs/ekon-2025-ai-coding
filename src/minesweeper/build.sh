#!/usr/bin/env bash
set -euo pipefail

echo "[build] Ensuring bundle directories…"
mkdir -p build/Minesweeper.app/Contents/{MacOS,Resources}

if ! command -v fpc >/dev/null 2>&1; then
  echo "[build] Error: fpc not found in PATH" >&2
  exit 1
fi

# Create a minimal Info.plist if missing
PLIST="build/Minesweeper.app/Contents/Info.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "[build] Creating Info.plist…"
  cat > "$PLIST" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>minesweeper</string>
  <key>CFBundleIdentifier</key>
  <string>com.example.minesweeper</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Minesweeper</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST
fi

echo "[build] Compiling Cocoa app for Apple Silicon (direct link)…"
set +e
fpc -MObjFPC -Sh -Si -O2 -B \
    -Fusrc -Fusrc/core -Fusrc/macOS \
    -Tdarwin -Paarch64 \
    -k-framework -kCocoa \
    -FEbuild/Minesweeper.app/Contents/MacOS \
    src/macOS/Main.pas
FPC_STATUS=$?
set -e

if [[ $FPC_STATUS -ne 0 ]]; then
  echo "[build] Direct link failed. Retrying with manual link workaround…"
  fpc -MObjFPC -Sh -Si -O2 -B -Cn \
      -Fusrc -Fusrc/core -Fusrc/macOS \
      -Tdarwin -Paarch64 \
      -k-framework -kCocoa \
      -FEbuild/Minesweeper.app/Contents/MacOS \
      src/macOS/Main.pas

  # Ensure empty order file to avoid ld crashes on some toolchains
  SOF="build/Minesweeper.app/Contents/MacOS/symbol_order.fpc"
  : > "$SOF"

  echo "[build] Linking…"
  LINK_SCRIPT="build/Minesweeper.app/Contents/MacOS/ppaslink.sh"
  if command -v sed >/dev/null 2>&1; then
    sed -E -i '' 's/-order_file [^ ]+//g' "$LINK_SCRIPT" || true
    sed -E -i '' 's#/usr/bin/ld#& -macos_version_min 11.0#g' "$LINK_SCRIPT" || true
    # Prefer ld-classic if available (works around ld64 crashes on some CLT versions)
    if [ -x "/Library/Developer/CommandLineTools/usr/bin/ld-classic" ]; then
      sed -E -i '' 's#/Library/Developer/CommandLineTools/usr/bin/ld#&-classic#g' "$LINK_SCRIPT" || true
    fi
  fi
  # As a fallback, try with classic ld via env var as well
  export LD_CLASSIC=1
  sh "$LINK_SCRIPT" || sh "$LINK_SCRIPT"
fi

# FPC names the output after the program (Main). Rename to match CFBundleExecutable
if [[ -f build/Minesweeper.app/Contents/MacOS/Main ]]; then
  mv -f build/Minesweeper.app/Contents/MacOS/Main build/Minesweeper.app/Contents/MacOS/minesweeper
fi

echo "[build] Done. Launch with: open build/Minesweeper.app"

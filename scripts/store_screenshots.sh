#!/usr/bin/env bash
# Regenerates the App Store screenshots into AppStore/screenshots/en (1320×2868, 6.9") and
# AppStore/screenshots/en-6.5 (1284×2778) and en-6.3 (1206×2622, the "medium display" slot).
#   1. StoreScreenshotTests captures raw screens with generated demo data (no real channels)
#   2. make_store_screenshots.py adds the headline, device frame and background
#
# Device: DEVICE="iPhone 17 Pro Max" (must be a 6.9-inch iPhone for the right size).
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${DEVICE:-iPhone 17 Pro Max}"
WORK=build/store-screenshots

UDID=$(xcrun simctl list devices available | grep -F -m1 "    ${DEVICE} (" \
  | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' || true)
if [[ -z "$UDID" ]]; then
  echo "Simulator \"${DEVICE}\" not found." >&2
  exit 1
fi

rm -rf "$WORK"
mkdir -p "$WORK/raw"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
# Fresh install: DEBUG sample data is re-seeded and no old draft or settings leak in.
xcrun simctl uninstall "$UDID" com.irovi.app 2>/dev/null || true
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 --dataNetwork wifi

echo "▸ Capturing screens on ${DEVICE}…"
TEST_RUNNER_STORE_SCREENSHOTS=1 xcodebuild -project Irovi.xcodeproj -scheme Irovi \
  -destination "id=$UDID" -derivedDataPath build/DerivedData -resultBundlePath "$WORK/result.xcresult" \
  -only-testing:IroviUITests/StoreScreenshotTests -quiet test 2>&1 | sed "/IDETestOperationsObserverDebug/d"
xcrun simctl status_bar "$UDID" clear

xcrun xcresulttool export attachments --path "$WORK/result.xcresult" --output-path "$WORK/raw" >/dev/null
python3 - "$WORK/raw" <<'EOF'
import json, os, re, sys
folder = sys.argv[1]
for test in json.load(open(os.path.join(folder, 'manifest.json'))):
    for attachment in test.get('attachments', []):
        name = re.sub(r'_\d+_[0-9A-F-]+', '', attachment.get('suggestedHumanReadableName', attachment['exportedFileName']))
        os.rename(os.path.join(folder, attachment['exportedFileName']), os.path.join(folder, name))
EOF

echo "▸ Composing store images…"
python3 scripts/make_store_screenshots.py "$WORK/raw" --out AppStore/screenshots

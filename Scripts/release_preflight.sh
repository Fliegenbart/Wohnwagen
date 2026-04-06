#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/CamperReady.xcodeproj"
SCHEME="CamperReady"
ARCHIVE_PATH="/tmp/CamperReady-Preflight.xcarchive"

find_simulator_id() {
  local simulator_id
  simulator_id="$(
    xcrun simctl list devices available |
      awk -F '[()]' '/iPhone/ { print $2; exit }'
  )"

  if [[ -z "$simulator_id" ]]; then
    echo "Kein verfuegbares iPhone-Simulatorziel gefunden." >&2
    echo "Bitte starte Xcode einmal und installiere einen iPhone-Simulator." >&2
    exit 1
  fi

  echo "$simulator_id"
}

SIMULATOR_ID="$(find_simulator_id)"

echo "1/3 Simulator-Build wird geprueft..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  build

echo
echo "2/3 Tests werden geprueft..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  test

echo
echo "3/3 Release-Archiv ohne Signierung wird geprueft..."
rm -rf "$ARCHIVE_PATH"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  CODE_SIGNING_ALLOWED=NO \
  archive \
  -archivePath "$ARCHIVE_PATH"

echo
echo "Preflight erfolgreich."
echo "Die App baut, die Tests laufen, und ein Release-Archiv ist technisch moeglich."
echo "Naechster Schritt fuer TestFlight:"
echo "DEVELOPMENT_TEAM=DEINTEAMID bash Scripts/archive_for_testflight.sh"

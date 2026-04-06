#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/CamperReady.xcodeproj"
SCHEME="CamperReady"
CONFIG_PATH="$ROOT_DIR/CamperReady/Config/Shared.xcconfig"

read_setting() {
  local key="$1"
  awk -F '=' -v lookup="$key" '
    $1 ~ lookup {
      gsub(/[[:space:]]/, "", $2)
      print $2
      exit
    }
  ' "$CONFIG_PATH"
}

TEAM_ID="${DEVELOPMENT_TEAM:-${APP_DEVELOPMENT_TEAM:-}}"
ALLOW_UNSIGNED_ARCHIVE="${ALLOW_UNSIGNED_ARCHIVE:-0}"
VERSION="${MARKETING_VERSION_OVERRIDE:-$(read_setting MARKETING_VERSION)}"
BUILD_NUMBER="${CURRENT_PROJECT_VERSION_OVERRIDE:-$(read_setting CURRENT_PROJECT_VERSION)}"

if [[ -z "$VERSION" || -z "$BUILD_NUMBER" ]]; then
  echo "Version oder Build-Nummer konnte nicht aus Shared.xcconfig gelesen werden." >&2
  exit 1
fi

if [[ -z "$TEAM_ID" && "$ALLOW_UNSIGNED_ARCHIVE" != "1" ]]; then
  echo "Kein Development-Team gesetzt." >&2
  echo "Bitte starte den Befehl so:" >&2
  echo "DEVELOPMENT_TEAM=DEINTEAMID bash Scripts/archive_for_testflight.sh" >&2
  echo "Wenn du nur die Technik pruefen willst, kannst du temporaer ALLOW_UNSIGNED_ARCHIVE=1 setzen." >&2
  exit 1
fi

ARCHIVE_DIR="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"
ARCHIVE_NAME="CamperReady ${VERSION} (${BUILD_NUMBER}) $(date +%H-%M-%S).xcarchive"
ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_NAME"

mkdir -p "$ARCHIVE_DIR"
rm -rf "$ARCHIVE_PATH"

echo "Archiv wird erstellt:"
echo "$ARCHIVE_PATH"
echo

if [[ "$ALLOW_UNSIGNED_ARCHIVE" == "1" ]]; then
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGNING_ALLOWED=NO \
    archive \
    -archivePath "$ARCHIVE_PATH"
else
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    archive \
    -archivePath "$ARCHIVE_PATH"
fi

echo
echo "Archiv erfolgreich erstellt."
echo "Version: $VERSION"
echo "Build: $BUILD_NUMBER"
echo
echo "Naechste Schritte in Xcode:"
echo "1. Xcode oeffnen"
echo "2. Window > Organizer"
echo "3. Archiv auswaehlen"
echo "4. Distribute App > App Store Connect > Upload"
echo
echo "Archiv liegt hier:"
echo "$ARCHIVE_PATH"

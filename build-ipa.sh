#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$ROOT/Unity-iPhone.xcodeproj"
SCHEME="Unity-iPhone"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="$ROOT/build"
ARCHIVE="$BUILD_DIR/${SCHEME}.xcarchive"
EXPORT_DIR="$BUILD_DIR/ipa"
EXPORT_OPTIONS="$ROOT/ExportOptions.plist"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must run on macOS with Xcode installed."
  exit 2
fi
if [[ ! -d "$PROJECT" ]]; then
  echo "Missing project: $PROJECT"
  exit 3
fi

rm -rf "$ARCHIVE" "$EXPORT_DIR"
mkdir -p "$BUILD_DIR"

if [[ "${UNSIGNED:-0}" == "1" ]]; then
  DERIVED_DATA="$BUILD_DIR/DerivedData"
  APP="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/${SCHEME}.app"
  PAYLOAD="$BUILD_DIR/Payload"

  rm -rf "$DERIVED_DATA" "$PAYLOAD"
  mkdir -p "$EXPORT_DIR"

  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphoneos \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build

  if [[ ! -d "$APP" ]]; then
    echo "Missing built app: $APP"
    exit 4
  fi

  mkdir -p "$PAYLOAD"
  cp -R "$APP" "$PAYLOAD/"
  (cd "$BUILD_DIR" && ditto -c -k --sequesterRsrc --keepParent Payload "ipa/${SCHEME}-unsigned.ipa")
  echo "Unsigned IPA created at: $EXPORT_DIR/${SCHEME}-unsigned.ipa"
  exit 0
fi

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -allowProvisioningUpdates \
  -archivePath "$ARCHIVE" \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_DIR"

echo "IPA created under: $EXPORT_DIR"

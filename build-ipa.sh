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

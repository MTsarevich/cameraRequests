#!/bin/sh

# Xcode Cloud hook — runs before each `xcodebuild`.
#
# Sets the app build number to Xcode Cloud's auto-incrementing CI_BUILD_NUMBER,
# so every TestFlight upload gets a unique build number without manual bumping.
# (TestFlight rejects a build if its build number was already used.)

set -e

if [ -z "$CI_BUILD_NUMBER" ]; then
  echo "ℹ️  CI_BUILD_NUMBER not set — not running under Xcode Cloud, skipping."
  exit 0
fi

PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/cameraRequests.xcodeproj/project.pbxproj"

if [ ! -f "$PBXPROJ" ]; then
  echo "❌ project.pbxproj not found at: $PBXPROJ"
  exit 1
fi

echo "🔢 Setting build number (CURRENT_PROJECT_VERSION) to $CI_BUILD_NUMBER"
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" "$PBXPROJ"
echo "✅ Build number updated."

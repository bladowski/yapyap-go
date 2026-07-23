#!/bin/bash
# YapYap Mobile App Deployment Script
# Run this on a machine with Flutter SDK and ADB installed.
# Device must already be connected via wireless ADB.

set -e

echo "=== YapYap Mobile Deployment ==="

# Ensure ADB device is connected
if ! adb devices | grep -q "device$"; then
  echo "Error: No ADB device connected. Run: adb connect <ip>:<port>"
  exit 1
fi

echo "Device: $(adb devices | grep device$ | head -1)"

# Build and install Passenger App
echo ""
echo "--- Passenger App ---"
cd mobile-passenger
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
echo "✓ Passenger app installed"
cd ..

# Build and install Driver App
echo ""
echo "--- Driver App ---"
cd mobile-driver
flutter pub get
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
echo "✓ Driver app installed"
cd ..

echo ""
echo "=== Both APKs installed successfully ==="
adb shell pm list packages | grep yapyap

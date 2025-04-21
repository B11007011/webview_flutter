#!/bin/bash

set -e

echo "🔍 Fixing Android Gradle project structure..."

# Create a temporary directory for operations
TEMP_DIR=$(mktemp -d)

# Backup important files from current Android structure
echo "📋 Backing up important files..."
mkdir -p android_backup
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  mkdir -p android_backup/app/src/main
  cp -r android/app/src/main/kotlin android_backup/app/src/main/ 2>/dev/null || true
  cp android/app/src/main/AndroidManifest.xml android_backup/app/src/main/ 2>/dev/null || true
  cp -r android/app/src/main/res android_backup/app/src/main/ 2>/dev/null || true
fi

if [ -f "android/app/src/debug/AndroidManifest.xml" ]; then
  mkdir -p android_backup/app/src/debug
  cp android/app/src/debug/AndroidManifest.xml android_backup/app/src/debug/ 2>/dev/null || true
fi

if [ -f "android/app/src/profile/AndroidManifest.xml" ]; then
  mkdir -p android_backup/app/src/profile
  cp android/app/src/profile/AndroidManifest.xml android_backup/app/src/profile/ 2>/dev/null || true
fi

# Create backup of local.properties if it exists
if [ -f "android/local.properties" ]; then
  cp android/local.properties android_backup/ 2>/dev/null || true
fi

# Get the current app signing configuration if available
if grep -q "signingConfig" android/app/build.gradle.kts 2>/dev/null; then
  mkdir -p android_backup/app
  grep -A 20 "signingConfig" android/app/build.gradle.kts > android_backup/app/signing_config.txt 2>/dev/null || true
fi

echo "🔄 Replacing Android directory with correct structure..."
# Rename the old android directory
mv android android_old

# Copy the new Android directory from temp project
cp -r temp_project/temp_app/android .

echo "🔄 Restoring custom configurations..."

# Update application ID and NDK version in build.gradle.kts
if [ -f "android/app/build.gradle.kts" ]; then
  # Create a new build.gradle.kts with our customizations
  NEW_GRADLE="$TEMP_DIR/new_build.gradle.kts"
  touch "$NEW_GRADLE"
  
  while IFS= read -r line; do
    if [[ "$line" == *"ndkVersion = flutter.ndkVersion"* ]]; then
      echo '    ndkVersion = "27.0.12077973"  // Fixed NDK version for webview_flutter_android compatibility' >> "$NEW_GRADLE"
    elif [[ "$line" == *"namespace = "* ]]; then
      echo '    namespace = "com.example.WaterWise"' >> "$NEW_GRADLE"
    elif [[ "$line" == *"applicationId = "* ]]; then
      echo '        applicationId = "com.example.WaterWise"' >> "$NEW_GRADLE"
    elif [[ "$line" == *"minSdk = flutter.minSdkVersion"* ]]; then
      echo '        minSdk = 21  // Updated for webview_flutter_android compatibility' >> "$NEW_GRADLE"
    else
      echo "$line" >> "$NEW_GRADLE"
    fi
  done < "android/app/build.gradle.kts"
  
  # Replace original with new build file
  mv "$NEW_GRADLE" "android/app/build.gradle.kts"
fi

# Update application ID in build.gradle (if it exists)
if [ -f "android/app/build.gradle" ]; then
  sed -i.bak 's/applicationId "com.example.waterwise"/applicationId "com.example.WaterWise"/g' android/app/build.gradle
  sed -i.bak 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 21/g' android/app/build.gradle
  sed -i.bak 's/ndkVersion flutter.ndkVersion/ndkVersion "27.0.12077973"/g' android/app/build.gradle
  sed -i.bak 's/namespace "com.example.waterwise.waterwise"/namespace "com.example.WaterWise"/g' android/app/build.gradle
  rm android/app/build.gradle.bak 2>/dev/null || true
fi

# Copy back the manifest files and kotlin directory if they exist
if [ -f "android_backup/app/src/main/AndroidManifest.xml" ]; then
  cp android_backup/app/src/main/AndroidManifest.xml android/app/src/main/
fi

if [ -d "android_backup/app/src/main/kotlin" ]; then
  rm -rf android/app/src/main/kotlin
  cp -r android_backup/app/src/main/kotlin android/app/src/main/
fi

if [ -d "android_backup/app/src/main/res" ]; then
  cp -r android_backup/app/src/main/res/* android/app/src/main/res/ 2>/dev/null || true
fi

# Restore debug and profile manifests if they exist
if [ -f "android_backup/app/src/debug/AndroidManifest.xml" ]; then
  cp android_backup/app/src/debug/AndroidManifest.xml android/app/src/debug/
fi

if [ -f "android_backup/app/src/profile/AndroidManifest.xml" ]; then
  cp android_backup/app/src/profile/AndroidManifest.xml android/app/src/profile/
fi

# Restore local.properties if it exists
if [ -f "android_backup/local.properties" ]; then
  cp android_backup/local.properties android/
fi

# Create or update app name in strings.xml
mkdir -p android/app/src/main/res/values
echo '<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">WaterWise</string>
</resources>' > android/app/src/main/res/values/strings.xml

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ Android project structure has been fixed."
echo "📝 Next steps:"
echo "1. Run 'flutter pub get'"
echo "2. Run 'flutter build apk --release' to build the release APK" 
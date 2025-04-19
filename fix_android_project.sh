#!/bin/bash

set -e
set -x

echo "🔍 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
ORIGINAL_DIR=$(pwd)
PROJECT_NAME=$(basename "$ORIGINAL_DIR")
PACKAGE_NAME="com.example.WaterWise" # Should match your current package name
APP_NAME="WaterWise"

echo "📁 Creating temporary Flutter project in $TEMP_DIR"
cd "$TEMP_DIR"
flutter create --project-name "$PROJECT_NAME" --org "$PACKAGE_NAME" --platforms=android temp_project

echo "🔄 Backing up your custom Android files..."
mkdir -p "$TEMP_DIR/backup/android/app/src/main"
if [ -d "$ORIGINAL_DIR/android/app/src/main/kotlin" ]; then
  cp -r "$ORIGINAL_DIR/android/app/src/main/kotlin" "$TEMP_DIR/backup/android/app/src/main/"
fi
if [ -f "$ORIGINAL_DIR/android/app/src/main/AndroidManifest.xml" ]; then
  cp "$ORIGINAL_DIR/android/app/src/main/AndroidManifest.xml" "$TEMP_DIR/backup/android/app/src/main/"
fi
if [ -f "$ORIGINAL_DIR/android/app/build.gradle.kts" ]; then
  cp "$ORIGINAL_DIR/android/app/build.gradle.kts" "$TEMP_DIR/backup/android/app/"
fi
if [ -f "$ORIGINAL_DIR/android/app/proguard-rules.pro" ]; then
  cp "$ORIGINAL_DIR/android/app/proguard-rules.pro" "$TEMP_DIR/backup/android/app/"
fi

echo "🔄 Copying new Android project structure..."
cd "$ORIGINAL_DIR"
rm -rf android/.gradle android/build

# Remove old backup if it exists
if [ -d "android_old" ]; then
  echo "Removing previous backup in android_old..."
  rm -rf android_old
fi

# Move current android directory to backup
mv android android_old
cp -r "$TEMP_DIR/temp_project/android" .

echo "🔄 Restoring your custom files and configurations..."
# Restore Kotlin files if they exist
if [ -d "$TEMP_DIR/backup/android/app/src/main/kotlin" ]; then
  rm -rf android/app/src/main/kotlin
  cp -r "$TEMP_DIR/backup/android/app/src/main/kotlin" android/app/src/main/
fi

# Merge AndroidManifest.xml (keeping your custom permissions and settings)
if [ -f "$TEMP_DIR/backup/android/app/src/main/AndroidManifest.xml" ]; then
  # For this script, we'll manually extract and add permissions to avoid sed compatibility issues
  PERMISSIONS=$(grep "uses-permission" "$TEMP_DIR/backup/android/app/src/main/AndroidManifest.xml" | sort | uniq)
  USES_CLEARTEXT=$(grep -q "android:usesCleartextTraffic=\"true\"" "$TEMP_DIR/backup/android/app/src/main/AndroidManifest.xml" && echo "true" || echo "false")
  
  # Add permissions and attributes to the new manifest by creating a new file
  NEW_MANIFEST="$TEMP_DIR/new_manifest.xml"
  touch "$NEW_MANIFEST"
  
  # Read the new manifest line by line and insert our custom elements
  INSERTED_PERMISSIONS=false
  while IFS= read -r line; do
    # If we find the opening application tag and haven't inserted permissions yet
    if [[ "$line" == *"<application"* ]] && [ "$INSERTED_PERMISSIONS" = false ]; then
      # Insert permissions before application tag
      if [ -n "$PERMISSIONS" ]; then
        echo "$PERMISSIONS" >> "$NEW_MANIFEST"
      fi
      # Set inserted flag
      INSERTED_PERMISSIONS=true
      
      # Add usesCleartextTraffic if needed
      if [ "$USES_CLEARTEXT" = "true" ]; then
        # Add the attribute to the application tag
        line="${line/\<application/\<application android:usesCleartextTraffic=\"true\"}"
      fi
    fi
    echo "$line" >> "$NEW_MANIFEST"
  done < "android/app/src/main/AndroidManifest.xml"
  
  # Replace original with new manifest
  mv "$NEW_MANIFEST" "android/app/src/main/AndroidManifest.xml"
fi

# Always use the correct NDK and minSdk version
if [ -f "android/app/build.gradle.kts" ]; then
  # Create a new build.gradle.kts with our customizations
  NEW_GRADLE="$TEMP_DIR/new_build.gradle.kts"
  touch "$NEW_GRADLE"
  
  while IFS= read -r line; do
    if [[ "$line" == *"ndkVersion = flutter.ndkVersion"* ]]; then
      echo "    ndkVersion = \"27.0.12077973\"  // Updated NDK version for webview_flutter_android compatibility" >> "$NEW_GRADLE"
    elif [[ "$line" == *"minSdk = flutter.minSdkVersion"* ]]; then
      echo "        minSdk = 21 // Updated for webview_flutter_android compatibility" >> "$NEW_GRADLE"
    else
      echo "$line" >> "$NEW_GRADLE"
    fi
  done < "android/app/build.gradle.kts"
  
  # Replace original with new build file
  mv "$NEW_GRADLE" "android/app/build.gradle.kts"
elif [ -f "android/app/build.gradle" ]; then
  # Handle plain Gradle build files
  NEW_GRADLE="$TEMP_DIR/new_build.gradle"
  touch "$NEW_GRADLE"
  
  while IFS= read -r line; do
    if [[ "$line" == *"ndkVersion flutter.ndkVersion"* ]]; then
      echo "    ndkVersion \"27.0.12077973\"  // Updated NDK version for webview_flutter_android compatibility" >> "$NEW_GRADLE"
    elif [[ "$line" == *"minSdkVersion flutter.minSdkVersion"* ]]; then
      echo "        minSdkVersion 21 // Updated for webview_flutter_android compatibility" >> "$NEW_GRADLE"
    else
      echo "$line" >> "$NEW_GRADLE"
    fi
  done < "android/app/build.gradle"
  
  # Replace original with new build file
  mv "$NEW_GRADLE" "android/app/build.gradle"
fi

# Copy ProGuard rules
if [ -f "$TEMP_DIR/backup/android/app/proguard-rules.pro" ]; then
  cp "$TEMP_DIR/backup/android/app/proguard-rules.pro" android/app/
fi

echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"
mkdir -p android/.gradle # Create empty .gradle directory to prevent initial warning

echo "✅ Android project structure has been fixed."
echo "📝 Next steps:"
echo "1. Run 'flutter pub get'"
echo "2. Run 'flutter build apk --debug' to test the build"
echo "3. If any issues persist, check the Android project settings" 
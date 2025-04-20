#!/bin/bash

set -e
set -x

echo "🔍 Fixing splash screen for WaterWise app..."

# Create strings.xml with correct app name
mkdir -p android/app/src/main/res/values
echo '<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">WaterWise</string>
</resources>' > android/app/src/main/res/values/strings.xml

# Update AndroidManifest.xml to use the correct app name
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  # Create a backup
  cp android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml.bak
  
  # Update the label to WaterWise
  sed -i.bak 's/android:label="[^"]*"/android:label="WaterWise"/g' android/app/src/main/AndroidManifest.xml
  
  # Clean up the backup
  rm android/app/src/main/AndroidManifest.xml.bak
  echo "✅ Updated AndroidManifest.xml to use 'WaterWise' label"
else
  echo "❌ AndroidManifest.xml not found"
fi

# Update the application name in the code
if grep -q "webview_flutter" lib/main.dart; then
  sed -i.bak 's/webview_flutter/WaterWise/g' lib/main.dart
  rm lib/main.dart.bak
  echo "✅ Updated main.dart references from 'webview_flutter' to 'WaterWise'"
fi

# Create or update launch_background.xml
mkdir -p android/app/src/main/res/drawable
echo '<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
    <!-- You can add a logo here if desired -->
</layer-list>' > android/app/src/main/res/drawable/launch_background.xml

# Create or update styles.xml to ensure proper theming
mkdir -p android/app/src/main/res/values
echo '<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>' > android/app/src/main/res/values/styles.xml

# Run flutter clean to ensure rebuild with new resources
echo "🧹 Running flutter clean to refresh resources..."
flutter clean

echo "✅ Splash screen has been fixed."
echo "📝 Next steps:"
echo "1. Run 'flutter pub get'"
echo "2. Run 'flutter build apk --debug' to test the build"
echo "3. Check that the app shows 'WaterWise' on the splash screen" 
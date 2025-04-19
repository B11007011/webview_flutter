# WebView Flutter App

A Flutter application that wraps a web app inside a WebView with proper lifecycle management.

## Features

- WebView with proper lifecycle management
- Hybrid composition for better performance
- Proper handling of back button navigation
- Loading indicators and error handling
- Transparent background for seamless integration

## Setup and Build

### Prerequisites

- Flutter SDK (3.19.3 or later)
- Android SDK
- Android NDK (27.0.12077973 required for webview_flutter_android)

### Local Build

1. Clone the repository
2. Run `flutter pub get` to get dependencies
3. Run `flutter build apk --debug` to build a debug APK
4. Run `flutter build apk --release` to build a release APK

### CI/CD Build (GitHub Actions)

This project includes a GitHub Actions workflow for automating APK builds and releases.

If you encounter the "unsupported Gradle project" error, use the provided fix script:

```bash
chmod +x fix_android_project.sh
./fix_android_project.sh
flutter pub get
flutter build apk --debug
```

The fix script:
1. Creates a temporary Flutter project with proper structure
2. Preserves your custom Android settings
3. Replaces the Android project structure with a properly configured one
4. Configures the correct NDK version for webview_flutter_android

For more details, see the [CI/CD Setup Guide](CI_SETUP.md).

## Testing

To test the app:

1. Install on an Android device using `flutter run`
2. Verify back button navigation
3. Test offline behavior and error handling
4. Check app lifecycle behavior (background/foreground transitions)

## Troubleshooting

See the [CI/CD Setup Guide](CI_SETUP.md) for common issues and solutions.

## License

This project is licensed under the MIT License.

# CI/CD Setup Guide

This guide helps with setting up and troubleshooting the CI/CD pipeline for building APKs with GitHub Actions.

## Prerequisites

1. Flutter SDK (3.19.3 or later)
2. Android SDK
3. Gradle 8.3+
4. GitHub repository with Actions enabled

## Local Setup

Before pushing to GitHub, ensure your local environment is properly configured:

1. Fix your Android project structure using the provided script:
   ```bash
   chmod +x fix_android_project.sh
   ./fix_android_project.sh
   ```

2. Verify your `local.properties` file contains correct paths:
   ```bash
   echo "flutter.sdk=/path/to/flutter" > android/local.properties
   echo "sdk.dir=/path/to/android/sdk" >> android/local.properties
   ```

3. Test a local build:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter build apk --debug
   ```

## Common Issues and Solutions

### "Your app is using an unsupported Gradle project"

**Solution:**
- Run the `fix_android_project.sh` script to rebuild the Android project structure
- This script creates a temporary Flutter project, extracts the proper Gradle structure, and preserves your custom settings

### "No such file or directory: android/gradlew"

**Solution:**
- This is likely due to an unsupported Gradle project structure
- Run the `fix_android_project.sh` script to fix this issue
- This will ensure the Gradle wrapper files are properly set up

### "SDK location not found"

**Solution:**
- Check if `local.properties` file is correctly created
- In GitHub Actions, ensure environment variables `FLUTTER_HOME` and `ANDROID_SDK_ROOT` are correctly set

### Build Failures

**Solution:**
- Check Gradle and Android SDK version compatibility
- Make sure your NDK version is set correctly in `android/app/build.gradle.kts`
- If needed, update Gradle wrapper version in `android/gradle/wrapper/gradle-wrapper.properties`

## What the Fix Script Does

The `fix_android_project.sh` script:

1. Creates a temporary Flutter project with proper structure
2. Backs up your custom Android settings and files
3. Replaces your Android project with the properly structured one
4. Restores your custom settings:
   - Kotlin files
   - AndroidManifest.xml permissions and settings
   - NDK version
   - minSdkVersion
   - ProGuard rules
5. Cleans up temporary files

## GitHub Actions Workflow

The workflow performs these key steps:
1. Sets up Java 17
2. Sets up Gradle
3. Sets up Flutter
4. Creates `local.properties` file
5. Fixes Android project structure using our script
6. Builds the APK
7. Creates a GitHub release with the APK
8. Generates a QR code for easy download

## Manual Workflow Trigger

You can manually trigger the workflow in the GitHub Actions tab of your repository. 
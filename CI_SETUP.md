# CI/CD Setup Guide

This guide helps with setting up and troubleshooting the CI/CD pipeline for building APKs with GitHub Actions.

## Prerequisites

1. Flutter SDK (3.19.3 or later)
2. Android SDK
3. Gradle 8.3+
4. GitHub repository with Actions enabled

## Local Setup

Before pushing to GitHub, ensure your local environment is properly configured:

1. Run the `fix_gradle_wrapper.sh` script to ensure Gradle wrapper files are in place:
   ```bash
   chmod +x fix_gradle_wrapper.sh
   ./fix_gradle_wrapper.sh
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
   flutter build apk --release
   ```

## Common Issues and Solutions

### "No such file or directory: android/gradlew"

**Solution:**
- Ensure the Gradle wrapper files are properly set up in your repo
- Run the `fix_gradle_wrapper.sh` script to fix this issue
- Make sure your `android/gradle/wrapper` directory contains `gradle-wrapper.jar` and `gradle-wrapper.properties`

### "SDK location not found"

**Solution:**
- Check if `local.properties` file is correctly created
- In GitHub Actions, ensure environment variables `FLUTTER_HOME` and `ANDROID_SDK_ROOT` are correctly set

### Build Failures

**Solution:**
- Check Gradle and Android SDK version compatibility
- Make sure your NDK version is set correctly in `android/app/build.gradle.kts`
- If needed, update Gradle wrapper version in `android/gradle/wrapper/gradle-wrapper.properties`

## GitHub Actions Workflow

The workflow performs these key steps:
1. Sets up Java 17
2. Sets up Gradle
3. Sets up Flutter
4. Creates `local.properties` file
5. Ensures Gradle wrapper is executable
6. Builds the APK
7. Creates a GitHub release with the APK
8. Generates a QR code for easy download

## Manual Workflow Trigger

You can manually trigger the workflow in the GitHub Actions tab of your repository. 
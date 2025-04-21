# Automated WebView App Generator

This tool allows you to generate custom WebView Android applications through an automated GitHub Actions workflow. 

## How to Generate a Custom APK

1. Navigate to the "Actions" tab in this GitHub repository
2. Select the "Build Customized WebView APK" workflow
3. Click "Run workflow" button
4. Fill in the following parameters:
   - **App Name**: The name of your application (will appear on the device)
   - **WebView URL**: The URL that will be loaded in the WebView
   - **Primary Color**: The main color theme of the app (hex color without # symbol)
   - **User ID**: Your unique identifier (used for APK naming)
   - **Build ID**: A unique build identifier (used for APK naming)
5. Click "Run workflow" to start the build process
6. Wait for the workflow to complete (typically 5-10 minutes)
7. Download your custom APK from the Artifacts section of the completed workflow

## APK Naming Convention

All generated APKs follow the naming convention: `userID_buildID.apk`

This ensures each build can be uniquely identified and tracked.

## Customization Details

The automated system will customize:

1. **App Name**: Changed in the app manifest and throughout the UI
2. **WebView URL**: The primary website loaded in the WebView
3. **Primary Color**: The main color theme of the application UI
4. **APK Filename**: Unique identifier based on user ID and build ID

## Troubleshooting

If you encounter issues with your generated APK:

1. Verify the URL is accessible and loads properly in mobile browsers
2. Ensure the color code is in the correct format (hex without # symbol)
3. Check that the app name doesn't contain special characters that could cause issues

For further assistance, please open an issue in this repository. 
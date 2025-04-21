# Automated WebView APK Generator

This project provides an automated pipeline for generating custom WebView Android applications using Flutter and GitHub Actions. It allows you to create branded WebView apps with custom URLs, names, and colors through an API or GitHub Actions workflow.

## Project Structure

- **Flutter WebView Template**: A fully functional Flutter WebView app that serves as the base for customization
- **GitHub Actions Workflow**: Automated build pipeline to customize and compile APKs
- **API**: HTTP API and command-line tool to trigger builds programmatically

## Key Features

- **Customizable App Properties**:
  - App Name: Define a custom app name that appears on the device
  - WebView URL: Specify the website to load in the WebView
  - Primary Color: Set the primary color theme for the app UI
  - Unique Build IDs: APK files are saved as userID_buildID.apk

- **Multiple Trigger Methods**:
  - GitHub Actions UI: Manually trigger builds via GitHub
  - REST API: HTTP endpoint for programmatic integration
  - Command Line: Python script for direct invocation

- **WebView Enhancements**:
  - Optimized mobile viewing experience
  - Status bar integration
  - Error handling with fallback URLs
  - Cross-origin request handling

## Getting Started

### Option 1: Use GitHub Actions Directly

1. Navigate to the "Actions" tab in this GitHub repository
2. Select the "Build Customized WebView APK" workflow
3. Click "Run workflow" button
4. Fill in the parameters (app name, URL, color, etc.)
5. Click "Run workflow" to start the build process
6. Download your custom APK from the Artifacts section

### Option 2: Use the API

The project includes a Flask-based API that can be deployed to trigger builds programmatically:

1. Set up the API server (see [API README](api/README.md))
2. Make HTTP requests to trigger builds:

```bash
curl -X POST http://your-api-server/api/build \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "app_name": "My WebView App",
    "url": "https://example.com",
    "color": "FF5722",
    "user_id": "user123"
  }'
```

### Option 3: Use the Command Line Tool

The project includes a Python script for direct command-line use:

```bash
python api/trigger_build.py \
  --token YOUR_GITHUB_TOKEN \
  --repo your/repo \
  --app-name "My App" \
  --url "https://example.com" \
  --color "FF5722" \
  --user-id "user123" \
  --wait
```

## Development

### Prerequisites

- Flutter SDK 3.19.0+
- GitHub repository with Actions enabled
- Python 3.8+ (for API and CLI)

### Setting Up Development Environment

1. Clone this repository
2. Install Flutter dependencies: `flutter pub get`
3. Test the WebView template: `flutter run`

### Modifying the WebView Template

The base WebView template is in `lib/main.dart`. You can modify this file to add additional features before building your customized versions.

### Customizing the Build Pipeline

The build pipeline is defined in `.github/workflows/build_apk.yml`. You can modify this file to add additional customization steps or build configurations.

## Deployment

### API Deployment

See [API README](api/README.md) for detailed deployment instructions.

### APK Distribution

Generated APKs are stored as GitHub Actions artifacts for 7 days by default. For a more permanent solution, consider setting up a storage system to archive the APKs after generation.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

# WebView APK Generator API

This API allows you to generate custom WebView Android applications through an automated GitHub Actions workflow. It uses the GitHub API to trigger a workflow that will build and customize a Flutter WebView app based on the parameters you provide.

## Setup

### Prerequisites

- Python 3.8+
- GitHub repository with the WebView Flutter template and configured workflow
- GitHub Personal Access Token with 'repo' scope

### Installation

1. Clone this repository
2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

3. Set up environment variables:
   ```
   export GITHUB_TOKEN=your_github_personal_access_token
   export GITHUB_REPO=your_username/your_repository
   export API_KEY=optional_api_key_for_security
   ```

### Running the API

#### Local Development

```
python app.py
```

The API will be available at `http://localhost:5000`

#### Production Deployment

For production, you can use Gunicorn:

```
gunicorn --bind 0.0.0.0:5000 app:app
```

#### Docker Deployment

Build and run the Docker container:

```
docker build -t webview-generator-api .
docker run -p 5000:8080 -e GITHUB_TOKEN=your_token -e GITHUB_REPO=your/repo webview-generator-api
```

## API Usage

### Trigger a build

**Endpoint:** POST `/api/build`

**Headers:**
- Content-Type: application/json
- X-API-Key: your_api_key (if API_KEY is set)

**Request Body:**
```json
{
  "app_name": "My WebView App",
  "url": "https://example.com",
  "color": "FF5722",
  "user_id": "user123",
  "build_id": "optional_custom_build_id"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Build triggered successfully",
  "build_id": "12345678",
  "user_id": "user123",
  "expected_filename": "user123_12345678.apk",
  "check_status_url": "https://github.com/your/repo/actions"
}
```

### Check API Health

**Endpoint:** GET `/health`

**Response:**
```json
{
  "status": "ok",
  "service": "WebView APK Generator API",
  "github_repo": "your/repo",
  "api_ready": true
}
```

## Command Line Usage

You can also use the included `trigger_build.py` script directly:

```
python trigger_build.py --token YOUR_GITHUB_TOKEN --repo your/repo --app-name "My App" --url "https://example.com" --color "FF5722" --user-id "user123" --build-id "001" --wait
```

The `--wait` flag will make the script wait for the workflow to complete and provide a download link.

## Error Handling

The API validates input parameters and returns appropriate error messages and status codes:

- 400: Bad Request (invalid or missing parameters)
- 401: Unauthorized (invalid API key)
- 500: Server Error (GitHub token not configured or other server errors)

## Notes

- The APK files are built with a unique naming convention: `userID_buildID.apk`
- The API doesn't store the APKs; they are uploaded as GitHub Actions artifacts
- Artifacts are available for download for 7 days by default
- You need a GitHub token with appropriate permissions to download the artifacts 
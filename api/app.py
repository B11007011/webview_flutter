#!/usr/bin/env python3
"""
WebView APK Generator API

A Flask-based REST API that triggers WebView APK builds via GitHub Actions.
Requires a GitHub personal access token with 'repo' scope.

Environment variables:
- GITHUB_TOKEN: GitHub Personal Access Token
- GITHUB_REPO: GitHub repository in format owner/repo (default: 'OWNER/REPO')
- API_KEY: Optional API key for securing endpoints
"""

import os
import uuid
from flask import Flask, request, jsonify
from flask_cors import CORS
from trigger_build import trigger_workflow

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load configuration from environment variables
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
GITHUB_REPO = os.environ.get('GITHUB_REPO', 'OWNER/REPO')
API_KEY = os.environ.get('API_KEY')  # Optional API key


class ArgumentsWrapper:
    """A simple wrapper to mimic argparse arguments structure"""
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


def validate_request(req_data):
    """Validate the incoming request data"""
    errors = []
    
    # Check for required fields
    required_fields = ['app_name', 'url', 'color', 'user_id']
    for field in required_fields:
        if field not in req_data:
            errors.append(f"Missing required field: {field}")
    
    # Validate color format (hex without #)
    if 'color' in req_data:
        color = req_data['color']
        if not (color.isalnum() and len(color) == 6):
            errors.append("Color must be a 6-character hex value without # (e.g., 'FF5722')")
    
    # Validate URL format
    if 'url' in req_data and not req_data['url'].startswith(('http://', 'https://')):
        errors.append("URL must start with http:// or https://")
    
    return errors


@app.route('/health', methods=['GET'])
def health_check():
    """Basic health check endpoint"""
    return jsonify({
        'status': 'ok',
        'service': 'WebView APK Generator API',
        'github_repo': GITHUB_REPO,
        'api_ready': bool(GITHUB_TOKEN),
    })


@app.route('/api/build', methods=['POST'])
def build_apk():
    """Endpoint to trigger an APK build"""
    # Check API key if configured
    if API_KEY:
        request_key = request.headers.get('X-API-Key')
        if not request_key or request_key != API_KEY:
            return jsonify({'error': 'Invalid or missing API key'}), 401
    
    # Check GitHub token
    if not GITHUB_TOKEN:
        return jsonify({'error': 'GitHub token not configured on server'}), 500
    
    # Get request data
    req_data = request.json
    if not req_data:
        return jsonify({'error': 'No JSON data provided'}), 400
    
    # Validate request data
    validation_errors = validate_request(req_data)
    if validation_errors:
        return jsonify({'error': 'Validation failed', 'details': validation_errors}), 400
    
    # Generate build ID if not provided
    if 'build_id' not in req_data or not req_data['build_id']:
        req_data['build_id'] = str(uuid.uuid4())[:8]
    
    # Create args wrapper for trigger_workflow function
    args = ArgumentsWrapper(
        token=GITHUB_TOKEN,
        repo=GITHUB_REPO,
        app_name=req_data['app_name'],
        url=req_data['url'],
        color=req_data['color'],
        user_id=req_data['user_id'],
        build_id=req_data['build_id'],
        wait=False
    )
    
    try:
        # Trigger the workflow
        build_id = trigger_workflow(args)
        
        # Return success response
        return jsonify({
            'status': 'success',
            'message': 'Build triggered successfully',
            'build_id': build_id,
            'user_id': req_data['user_id'],
            'expected_filename': f"{req_data['user_id']}_{build_id}.apk",
            'check_status_url': f"https://github.com/{GITHUB_REPO}/actions"
        })
        
    except Exception as e:
        return jsonify({
            'error': 'Failed to trigger build',
            'details': str(e)
        }), 500


if __name__ == '__main__':
    # Configuration warning
    if not GITHUB_TOKEN:
        print("WARNING: GITHUB_TOKEN environment variable not set. API will not function correctly.")
    if GITHUB_REPO == 'OWNER/REPO':
        print("WARNING: GITHUB_REPO environment variable not set. Using default placeholder value.")
    
    # Run the Flask app
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False) 
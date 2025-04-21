#!/usr/bin/env python3
"""
Trigger WebView APK Build API

This script triggers a GitHub Actions workflow to build a custom WebView APK.
It requires a GitHub personal access token with 'repo' scope.

Usage:
    python trigger_build.py --token GITHUB_TOKEN --app-name "My App" --url "https://example.com" --color "FF5722" --user-id "user123" --build-id "001"
"""

import argparse
import json
import requests
import sys
import time
import uuid


def parse_args():
    parser = argparse.ArgumentParser(description='Trigger WebView APK Build via GitHub Actions')
    parser.add_argument('--token', required=True, help='GitHub Personal Access Token')
    parser.add_argument('--repo', default='OWNER/REPO', help='GitHub repository in format owner/repo')
    parser.add_argument('--app-name', required=True, help='Name of the app')
    parser.add_argument('--url', required=True, help='WebView URL')
    parser.add_argument('--color', required=True, help='Primary color (hex without #)')
    parser.add_argument('--user-id', required=True, help='User ID for APK naming')
    parser.add_argument('--build-id', help='Build ID for APK naming (optional, auto-generated if not provided)')
    parser.add_argument('--wait', action='store_true', help='Wait for workflow to complete and return download URL')
    return parser.parse_args()


def trigger_workflow(args):
    """Trigger the GitHub Actions workflow with the provided parameters."""
    # Generate build ID if not provided
    build_id = args.build_id if args.build_id else str(uuid.uuid4())[:8]
    
    # GitHub API endpoint for workflow dispatch
    url = f"https://api.github.com/repos/{args.repo}/actions/workflows/build_apk.yml/dispatches"
    
    # Prepare headers and payload
    headers = {
        "Authorization": f"token {args.token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    payload = {
        "ref": "main",  # or your default branch
        "inputs": {
            "appName": args.app_name,
            "url": args.url,
            "primaryColor": args.color,
            "userId": args.user_id,
            "buildId": build_id
        }
    }
    
    # Trigger the workflow
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    
    if response.status_code == 204:
        print(f"Workflow triggered successfully!")
        print(f"Build ID: {build_id}")
        return build_id
    else:
        print(f"Error triggering workflow: {response.status_code}")
        print(response.text)
        sys.exit(1)


def wait_for_workflow_completion(args, build_id):
    """Wait for the triggered workflow to complete and get the download URL."""
    print("Waiting for workflow to complete...")
    
    # GitHub API endpoint for workflow runs
    url = f"https://api.github.com/repos/{args.repo}/actions/runs"
    
    headers = {
        "Authorization": f"token {args.token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    # Initial delay before checking
    time.sleep(10)
    
    # Loop to check workflow status
    while True:
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            print(f"Error checking workflow status: {response.status_code}")
            print(response.text)
            return None
        
        data = response.json()
        
        # Look for our workflow run
        for run in data.get("workflow_runs", []):
            # Check if this is our build by looking at the workflow name
            if run.get("name") == "Build Customized WebView APK":
                # Check if the run is recent (within the last hour)
                if "updated_at" in run:
                    # Further verify by checking artifacts
                    artifacts_url = run.get("artifacts_url")
                    artifacts_response = requests.get(artifacts_url, headers=headers)
                    
                    if artifacts_response.status_code == 200:
                        artifacts_data = artifacts_response.json()
                        for artifact in artifacts_data.get("artifacts", []):
                            if artifact.get("name") == f"{args.user_id}_{build_id}":
                                if run.get("status") == "completed":
                                    if run.get("conclusion") == "success":
                                        download_url = artifact.get("archive_download_url")
                                        return download_url
                                    else:
                                        print(f"Workflow failed with conclusion: {run.get('conclusion')}")
                                        return None
                                else:
                                    print(f"Workflow still running... Status: {run.get('status')}")
                                    time.sleep(30)  # Check every 30 seconds
                                    break
        
        # If we couldn't find our workflow run, wait and try again
        time.sleep(30)


def main():
    args = parse_args()
    
    # Trigger the workflow
    build_id = trigger_workflow(args)
    
    # If --wait flag is provided, wait for completion and get download URL
    if args.wait:
        download_url = wait_for_workflow_completion(args, build_id)
        if download_url:
            print(f"Workflow completed successfully!")
            print(f"Download URL: {download_url}")
            print(f"Note: You'll need to use the same GitHub token to download the artifact.")
            
            # Print curl command for easy downloading
            print("\nTo download the APK, use the following command:")
            print(f"curl -L -H 'Authorization: token YOUR_TOKEN' -o {args.user_id}_{build_id}.apk {download_url}")
        else:
            print("Workflow did not complete successfully or artifacts not found.")
    else:
        print("Workflow triggered. Check GitHub Actions tab for progress and results.")
        print(f"Expected APK name: {args.user_id}_{build_id}.apk")


if __name__ == "__main__":
    main() 
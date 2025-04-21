import { NextRequest, NextResponse } from 'next/server';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { initializeApp, getApps, cert } from 'firebase-admin/app';

// Initialize Firebase Admin if it hasn't been initialized
if (!getApps().length) {
  initializeApp({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

const auth = getAuth();
const db = getFirestore();

export async function POST(request: NextRequest) {
  try {
    // Get the auth token from the Authorization header
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json(
        { error: 'Unauthorized: Missing or invalid token' },
        { status: 401 }
      );
    }

    const token = authHeader.split('Bearer ')[1];
    
    // Verify the token and get the user
    const decodedToken = await auth.verifyIdToken(token);
    const userId = decodedToken.uid;

    // Get the request body
    const body = await request.json();
    const { url, appName, buildId } = body;

    if (!url || !appName || !buildId) {
      return NextResponse.json(
        { error: 'Bad request: Missing required fields' },
        { status: 400 }
      );
    }

    // Update the build status in Firestore
    await db.collection('builds').doc(buildId).update({
      status: 'building',
      updatedAt: new Date().toISOString(),
    });

    // Trigger GitHub Actions workflow
    const response = await fetch(
      `https://api.github.com/repos/${process.env.GITHUB_REPOSITORY}/actions/workflows/build-apk.yml/dispatches`,
      {
        method: 'POST',
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': `token ${process.env.GITHUB_TOKEN}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ref: 'main',
          inputs: {
            url,
            userId,
            appName,
            buildId,
          },
        }),
      }
    );

    if (!response.ok) {
      console.error('GitHub API error:', await response.text());
      
      // Update Firestore with the error
      await db.collection('builds').doc(buildId).update({
        status: 'failed',
        errorMessage: 'Failed to trigger build workflow',
        updatedAt: new Date().toISOString(),
      });
      
      return NextResponse.json(
        { error: 'Failed to trigger build workflow' },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Build triggered successfully',
      buildId,
    });
  } catch (error) {
    console.error('Error processing build request:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
} 
import { auth } from './firebase';

export async function triggerBuild(buildId: string, url: string, appName: string) {
  try {
    // Get the current user's ID token
    const user = auth.currentUser;
    if (!user) {
      throw new Error('User not authenticated');
    }
    
    const token = await user.getIdToken();
    
    // Call the API endpoint to trigger the build
    const response = await fetch('/api/build', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        buildId,
        url,
        appName,
      }),
    });
    
    const data = await response.json();
    
    if (!response.ok) {
      throw new Error(data.error || 'Failed to trigger build');
    }
    
    return data;
  } catch (error) {
    console.error('Error triggering build:', error);
    throw error;
  }
} 
import { db } from './firebase';
import { collection, doc, increment, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';

/**
 * Track an app download event
 * @param buildId The ID of the build that was downloaded
 * @param userId The ID of the user who owns the app
 */
export async function trackAppDownload(buildId: string, userId: string) {
  try {
    // Update the download count for this specific build
    await updateDoc(doc(db, 'builds', buildId), {
      downloadCount: increment(1),
      lastDownloadedAt: serverTimestamp(),
    });

    // Create an analytics event
    await setDoc(doc(collection(db, 'analytics')), {
      type: 'app_download',
      buildId,
      userId,
      timestamp: serverTimestamp(),
    });

    // Update user stats
    const userDocRef = doc(db, 'users', userId);
    await updateDoc(userDocRef, {
      totalDownloads: increment(1),
    });

    console.log('Download tracked successfully');
  } catch (error) {
    console.error('Error tracking download:', error);
  }
}

/**
 * Track an app view event when someone views the build details
 * @param buildId The ID of the build that was viewed
 */
export async function trackAppView(buildId: string) {
  try {
    // Update the view count for this specific build
    await updateDoc(doc(db, 'builds', buildId), {
      viewCount: increment(1),
    });
    
    console.log('View tracked successfully');
  } catch (error) {
    console.error('Error tracking view:', error);
  }
} 
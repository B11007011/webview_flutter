'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { doc, getDoc, onSnapshot } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';

interface BuildData {
  userId: string;
  url: string;
  appName: string;
  status: 'pending' | 'building' | 'completed' | 'failed';
  createdAt: string;
  downloadUrl?: string;
  errorMessage?: string;
}

export default function BuildDetailsPage({ params }: { params: { buildId: string } }) {
  const { buildId } = params;
  const router = useRouter();
  const [buildData, setBuildData] = useState<BuildData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchBuildData = async () => {
      try {
        // Get initial data
        const buildDoc = await getDoc(doc(db, 'builds', buildId));
        
        if (!buildDoc.exists()) {
          setError('Build not found');
          setLoading(false);
          return;
        }

        setBuildData(buildDoc.data() as BuildData);
        
        // Set up realtime listener for updates
        const unsubscribe = onSnapshot(
          doc(db, 'builds', buildId),
          (doc) => {
            if (doc.exists()) {
              setBuildData(doc.data() as BuildData);
            }
          },
          (err) => {
            console.error('Error listening to build updates:', err);
            toast.error('Error receiving real-time updates');
          }
        );

        setLoading(false);
        return () => unsubscribe();
      } catch (err) {
        console.error('Error fetching build data:', err);
        setError('Failed to load build data');
        setLoading(false);
      }
    };

    fetchBuildData();
  }, [buildId]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'building':
        return 'bg-blue-100 text-blue-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'failed':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'pending':
        return 'Queued for building';
      case 'building':
        return 'Build in progress';
      case 'completed':
        return 'Build completed successfully';
      case 'failed':
        return 'Build failed';
      default:
        return 'Unknown status';
    }
  };

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center p-8">
        <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-t-2 border-blue-500" />
      </div>
    );
  }

  if (error || !buildData) {
    return (
      <div className="p-8">
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600">Error</CardTitle>
          </CardHeader>
          <CardContent>
            <p>{error || 'Failed to load build details'}</p>
          </CardContent>
          <CardFooter>
            <Button onClick={() => router.push('/dashboard')}>Return to Dashboard</Button>
          </CardFooter>
        </Card>
      </div>
    );
  }

  return (
    <div className="py-6">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">Build Details</h1>
        <Button variant="outline" onClick={() => router.push('/dashboard')}>
          Back to Dashboard
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{buildData.appName}</CardTitle>
            <span
              className={`rounded-full px-3 py-1 text-xs font-medium ${getStatusColor(
                buildData.status
              )}`}
            >
              {buildData.status.toUpperCase()}
            </span>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="rounded-lg bg-gray-50 p-4">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <h3 className="text-sm font-medium text-gray-500">Website URL</h3>
                <p className="mt-1 break-all text-sm text-gray-900">{buildData.url}</p>
              </div>
              <div>
                <h3 className="text-sm font-medium text-gray-500">Created At</h3>
                <p className="mt-1 text-sm text-gray-900">
                  {new Date(buildData.createdAt).toLocaleString()}
                </p>
              </div>
              <div>
                <h3 className="text-sm font-medium text-gray-500">Build ID</h3>
                <p className="mt-1 text-sm font-mono text-gray-900">{buildId}</p>
              </div>
              <div>
                <h3 className="text-sm font-medium text-gray-500">Status</h3>
                <p className="mt-1 text-sm text-gray-900">{getStatusText(buildData.status)}</p>
              </div>
            </div>
          </div>

          {buildData.status === 'pending' || buildData.status === 'building' ? (
            <div className="rounded-lg bg-blue-50 p-4 text-center">
              <div className="flex items-center justify-center">
                <div className="mr-3 h-5 w-5 animate-spin rounded-full border-b-2 border-t-2 border-blue-600" />
                <p className="text-sm text-blue-700">
                  {buildData.status === 'pending'
                    ? 'Your app is queued for building. This may take a few minutes...'
                    : 'Building your app. Please wait...'}
                </p>
              </div>
            </div>
          ) : buildData.status === 'completed' ? (
            <div className="rounded-lg bg-green-50 p-4">
              <h3 className="text-base font-medium text-green-800">Build completed successfully!</h3>
              <p className="mt-2 text-sm text-green-700">
                Your app is ready for download. You can install it on your Android device.
              </p>
              <div className="mt-4">
                <Button className="w-full">
                  {buildData.downloadUrl ? (
                    <a
                      href={buildData.downloadUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex w-full items-center justify-center"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="mr-2 h-5 w-5"
                        viewBox="0 0 20 20"
                        fill="currentColor"
                      >
                        <path
                          fillRule="evenodd"
                          d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"
                          clipRule="evenodd"
                        />
                      </svg>
                      Download APK
                    </a>
                  ) : (
                    <span>Download APK (Demo)</span>
                  )}
                </Button>
              </div>
            </div>
          ) : (
            <div className="rounded-lg bg-red-50 p-4">
              <h3 className="text-base font-medium text-red-800">Build failed</h3>
              <p className="mt-2 text-sm text-red-700">
                {buildData.errorMessage || 'There was an error building your app. Please try again.'}
              </p>
              <div className="mt-4">
                <Button
                  onClick={() => router.push('/dashboard/create')}
                  className="w-full"
                  variant="outline"
                >
                  Try Again
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
} 
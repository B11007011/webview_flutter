'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { useAuth } from '@/lib/auth-context';
import { db } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';

interface AppBuild {
  id: string;
  appName: string;
  url: string;
  status: 'pending' | 'building' | 'completed' | 'failed';
  createdAt: string;
}

export default function AppsPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [apps, setApps] = useState<AppBuild[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchApps = async () => {
      if (!user) return;

      try {
        setLoading(true);
        const buildsQuery = query(
          collection(db, 'builds'),
          where('userId', '==', user.uid)
        );
        
        const querySnapshot = await getDocs(buildsQuery);
        const appsList: AppBuild[] = [];
        
        querySnapshot.forEach((doc) => {
          appsList.push({
            id: doc.id,
            ...(doc.data() as Omit<AppBuild, 'id'>),
          });
        });
        
        // Sort by creation date (newest first)
        appsList.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
        
        setApps(appsList);
      } catch (error) {
        console.error('Error fetching apps:', error);
        toast.error('Failed to load your apps');
      } finally {
        setLoading(false);
      }
    };

    fetchApps();
  }, [user]);

  const getStatusBadge = (status: string) => {
    let bgColor = '';
    let textColor = '';
    
    switch (status) {
      case 'pending':
        bgColor = 'bg-yellow-100';
        textColor = 'text-yellow-800';
        break;
      case 'building':
        bgColor = 'bg-blue-100';
        textColor = 'text-blue-800';
        break;
      case 'completed':
        bgColor = 'bg-green-100';
        textColor = 'text-green-800';
        break;
      case 'failed':
        bgColor = 'bg-red-100';
        textColor = 'text-red-800';
        break;
      default:
        bgColor = 'bg-gray-100';
        textColor = 'text-gray-800';
    }
    
    return (
      <span className={`rounded-full px-2 py-1 text-xs font-medium ${bgColor} ${textColor}`}>
        {status.toUpperCase()}
      </span>
    );
  };

  return (
    <div className="py-6">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">My Apps</h1>
        <Button onClick={() => router.push('/dashboard/create')}>Create New App</Button>
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-t-2 border-blue-500" />
        </div>
      ) : apps.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center p-8">
            <svg
              className="h-16 w-16 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1}
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              />
            </svg>
            <h2 className="mt-4 text-xl font-medium text-gray-900">No apps yet</h2>
            <p className="mt-1 text-center text-gray-500">
              Create your first app by converting a website into a mobile app.
            </p>
            <Button className="mt-6" onClick={() => router.push('/dashboard/create')}>
              Create Your First App
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {apps.map((app) => (
            <Card
              key={app.id}
              className="cursor-pointer transition-all hover:shadow-md"
              onClick={() => router.push(`/dashboard/builds/${app.id}`)}
            >
              <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg">{app.appName}</CardTitle>
                  {getStatusBadge(app.status)}
                </div>
              </CardHeader>
              <CardContent>
                <div className="mb-4 flex flex-col space-y-1">
                  <div className="text-xs text-gray-500">Website URL</div>
                  <div className="break-all text-sm">{app.url}</div>
                </div>
                <div className="flex flex-col space-y-1">
                  <div className="text-xs text-gray-500">Created</div>
                  <div className="text-sm">
                    {new Date(app.createdAt).toLocaleDateString()}
                  </div>
                </div>
                <div className="mt-4">
                  <Button
                    variant="outline"
                    size="sm"
                    className="w-full"
                    onClick={(e) => {
                      e.stopPropagation();
                      router.push(`/dashboard/builds/${app.id}`);
                    }}
                  >
                    View Details
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
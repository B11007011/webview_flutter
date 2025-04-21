'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useAuth } from '@/lib/auth-context';
import { db } from '@/lib/firebase';
import { doc, setDoc } from 'firebase/firestore';
import { triggerBuild } from '@/lib/api';

export default function CreateAppPage() {
  const { user } = useAuth();
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [url, setUrl] = useState('');
  const [appName, setAppName] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!url) {
      toast.error('Please enter a valid URL');
      return;
    }

    if (!appName) {
      toast.error('Please enter an app name');
      return;
    }

    if (!user || !user.uid) {
      toast.error('You must be logged in to create an app');
      router.push('/login');
      return;
    }

    try {
      setIsSubmitting(true);
      
      // Validate URL
      try {
        new URL(url);
      } catch (error) {
        toast.error('Please enter a valid URL (e.g., https://example.com)');
        setIsSubmitting(false);
        return;
      }

      // Create a new build record in Firestore
      const buildId = Date.now().toString();
      const userId = user.uid;
      
      // Add the build to Firestore
      try {
        await setDoc(doc(db, 'builds', buildId), {
          userId,
          url,
          appName,
          status: 'pending',
          createdAt: new Date().toISOString(),
        });
      } catch (error: any) {
        console.error('Firestore error:', error);
        if (error.code === 'permission-denied') {
          toast.error('Permission denied. Please check Firebase security rules.');
        } else {
          toast.error(`Error creating build record: ${error.message || 'Unknown error'}`);
        }
        setIsSubmitting(false);
        return;
      }

      // Trigger the build process
      try {
        await triggerBuild(buildId, url, appName);
        toast.success('Build request submitted successfully!');
      } catch (error: any) {
        console.error('Error triggering build:', error);
        toast.error(`Failed to start build process: ${error.message || 'Unknown error'}`);
      }
      
      // Redirect to the build details page
      router.push(`/dashboard/builds/${buildId}`);
    } catch (error: any) {
      console.error('Error submitting build:', error);
      toast.error(`Failed to submit build request: ${error.message || 'Please try again'}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="py-6">
      <h1 className="text-2xl font-semibold text-gray-900">Create New App</h1>
      <p className="mt-1 text-sm text-gray-500">
        Enter your website details to generate a custom native app.
      </p>

      <div className="mt-8">
        <Card className="mx-auto max-w-2xl">
          <form onSubmit={handleSubmit}>
            <CardHeader>
              <CardTitle>Website Details</CardTitle>
              <CardDescription>
                Provide the URL of the website you want to convert to an app
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="appName">App Name</Label>
                <Input
                  id="appName"
                  placeholder="My Awesome App"
                  value={appName}
                  onChange={(e) => setAppName(e.target.value)}
                  required
                />
                <p className="text-xs text-gray-500">
                  This will be the name displayed on the app icon and home screen
                </p>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="url">Website URL</Label>
                <Input
                  id="url"
                  type="url"
                  placeholder="https://example.com"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  required
                />
                <p className="text-xs text-gray-500">
                  Enter the full URL including https:// or http://
                </p>
              </div>
            </CardContent>
            <CardFooter className="flex justify-between">
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => router.back()}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? (
                  <>
                    <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-t-transparent" />
                    Building...
                  </>
                ) : (
                  'Create App'
                )}
              </Button>
            </CardFooter>
          </form>
        </Card>
      </div>
    </div>
  );
} 
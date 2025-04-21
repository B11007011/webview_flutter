'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth-context';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import ProtectedRoute from '@/components/ProtectedRoute';
import { toast } from 'sonner';

export default function ProfilePage() {
  const router = useRouter();
  const { user, signOut } = useAuth();
  const [isSigningOut, setIsSigningOut] = useState(false);

  const handleSignOut = async () => {
    try {
      setIsSigningOut(true);
      await signOut();
      toast.success('Successfully signed out');
      router.push('/login');
    } catch (error) {
      console.error('Error signing out:', error);
      toast.error('Failed to sign out');
    } finally {
      setIsSigningOut(false);
    }
  };

  return (
    <ProtectedRoute>
      <div className="py-6 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <h1 className="text-2xl font-semibold text-gray-900">Profile</h1>
        
        <div className="mt-6 max-w-3xl">
          <Card>
            <CardHeader>
              <CardTitle>Account Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="rounded-lg bg-gray-50 p-4">
                <div className="space-y-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-500">Email</h3>
                    <p className="mt-1 text-sm text-gray-900">{user?.email}</p>
                  </div>
                  
                  {user?.displayName && (
                    <div>
                      <h3 className="text-sm font-medium text-gray-500">Name</h3>
                      <p className="mt-1 text-sm text-gray-900">{user.displayName}</p>
                    </div>
                  )}
                  
                  <div>
                    <h3 className="text-sm font-medium text-gray-500">Account Created</h3>
                    <p className="mt-1 text-sm text-gray-900">
                      {user?.metadata.creationTime
                        ? new Date(user.metadata.creationTime).toLocaleDateString()
                        : 'Unknown'}
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="rounded-lg border border-gray-200 p-4">
                <h3 className="text-base font-medium text-gray-900">Subscription</h3>
                <div className="mt-2">
                  <span className="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">
                    Free Plan
                  </span>
                </div>
                <p className="mt-2 text-sm text-gray-500">
                  You're currently on the free plan. Upgrade to unlock additional features.
                </p>
                <Button
                  variant="outline"
                  className="mt-4"
                  onClick={() => toast.info('Subscription management coming soon!')}
                >
                  Manage Subscription
                </Button>
              </div>
              
              <div className="flex items-center justify-between">
                <Button
                  variant="outline"
                  onClick={() => router.push('/dashboard')}
                >
                  Back to Dashboard
                </Button>
                <Button
                  variant="destructive"
                  onClick={handleSignOut}
                  disabled={isSigningOut}
                >
                  {isSigningOut ? (
                    <>
                      <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-t-transparent" />
                      Signing out...
                    </>
                  ) : (
                    'Sign out'
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </ProtectedRoute>
  );
} 
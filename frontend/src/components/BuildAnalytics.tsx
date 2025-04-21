import { useEffect, useState } from 'react';
import { db } from '../lib/firebase';
import { doc, getDoc } from 'firebase/firestore';
import { Box, Card, CardContent, Typography, CircularProgress, Grid } from '@mui/material';
import { Download, Visibility } from '@mui/icons-material';

interface BuildAnalyticsProps {
  buildId: string;
}

interface AnalyticsData {
  downloadCount: number;
  viewCount: number;
  lastDownloadedAt: Date | null;
}

export const BuildAnalytics = ({ buildId }: BuildAnalyticsProps) => {
  const [loading, setLoading] = useState(true);
  const [analytics, setAnalytics] = useState<AnalyticsData>({
    downloadCount: 0,
    viewCount: 0,
    lastDownloadedAt: null,
  });
  
  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        setLoading(true);
        const buildDoc = await getDoc(doc(db, 'builds', buildId));
        
        if (buildDoc.exists()) {
          const data = buildDoc.data();
          setAnalytics({
            downloadCount: data.downloadCount || 0,
            viewCount: data.viewCount || 0,
            lastDownloadedAt: data.lastDownloadedAt ? new Date(data.lastDownloadedAt.toDate()) : null,
          });
        }
      } catch (error) {
        console.error('Error fetching analytics:', error);
      } finally {
        setLoading(false);
      }
    };

    if (buildId) {
      fetchAnalytics();
    }
  }, [buildId]);

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" my={2}>
        <CircularProgress size={24} />
      </Box>
    );
  }

  return (
    <Card variant="outlined" sx={{ mb: 2 }}>
      <CardContent>
        <Typography variant="h6" component="div" gutterBottom>
          Download Statistics
        </Typography>
        <Grid container spacing={3}>
          <Grid item xs={6}>
            <Box display="flex" alignItems="center">
              <Download color="primary" sx={{ mr: 1 }} />
              <Box>
                <Typography variant="h4">{analytics.downloadCount}</Typography>
                <Typography variant="body2" color="text.secondary">
                  Downloads
                </Typography>
              </Box>
            </Box>
          </Grid>
          <Grid item xs={6}>
            <Box display="flex" alignItems="center">
              <Visibility color="primary" sx={{ mr: 1 }} />
              <Box>
                <Typography variant="h4">{analytics.viewCount}</Typography>
                <Typography variant="body2" color="text.secondary">
                  Views
                </Typography>
              </Box>
            </Box>
          </Grid>
        </Grid>
        
        {analytics.lastDownloadedAt && (
          <Typography variant="caption" display="block" color="text.secondary" sx={{ mt: 2 }}>
            Last downloaded: {analytics.lastDownloadedAt.toLocaleString()}
          </Typography>
        )}
      </CardContent>
    </Card>
  );
};

export default BuildAnalytics; 
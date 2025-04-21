# WebView SaaS Platform Frontend

This is the frontend web application for the WebView SaaS Platform, built with Next.js, Firebase, and Tailwind CSS.

## Features

- **User Authentication**: Google Sign-in integration
- **Dashboard UI**: Clean and responsive interface for managing WebView apps
- **App Creation**: Convert websites into Android APK files
- **Real-time Status Updates**: Track build progress in real-time
- **Profile Management**: User profile and settings

## Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Auth**: Firebase Authentication
- **Database**: Firebase Firestore
- **Styling**: Tailwind CSS + shadcn/ui
- **State Management**: React Context API
- **Build Pipeline**: GitHub Actions

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Firebase project

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/webview-saas.git
   cd webview-saas/frontend
   ```

2. Install dependencies
   ```bash
   npm install
   ```

3. Set up environment variables
   ```bash
   cp .env.local.example .env.local
   ```
   
   Edit `.env.local` with your Firebase and GitHub credentials.

4. Start the development server
   ```bash
   npm run dev
   ```

5. Open [http://localhost:3000](http://localhost:3000) in your browser

### Firebase Setup

1. Create a new Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Enable Authentication with Google provider
3. Create a Firestore database
4. Generate a new web app configuration and add it to your .env.local file
5. For server-side functionality, generate a service account key and add it to your .env.local file

### GitHub Actions Setup

1. Create a GitHub repository for the Flutter WebView Template
   - Clone the existing WebView Flutter project
   - Push it to a new repository
2. Add the GitHub workflow file to `.github/workflows/build-apk.yml`
3. Configure the required secrets in your GitHub repository settings

## Project Structure

```
frontend/
├── public/               # Static assets
├── src/
│   ├── app/             # App Router pages
│   │   ├── api/         # API routes
│   │   ├── dashboard/   # Dashboard pages
│   │   ├── login/       # Authentication pages
│   │   ├── profile/     # User profile pages
│   ├── components/      # Reusable components
│   │   ├── ui/          # UI components
│   ├── lib/             # Utility functions
│   │   ├── firebase.ts  # Firebase configuration
│   │   ├── auth-context.tsx # Authentication context
├── .env.local.example   # Environment variables template
├── next.config.ts       # Next.js configuration
├── tailwind.config.js   # Tailwind CSS configuration
```

## Deployment

### Vercel Deployment

1. Push your code to a GitHub repository
2. Import the project in Vercel dashboard
3. Configure environment variables
4. Deploy

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

This project is licensed under the MIT License.

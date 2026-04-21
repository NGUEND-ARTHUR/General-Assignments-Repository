# UniAttend Web Deployment Guide

This guide deploys Flutter web to Vercel and connects it to your backend tunnel.

## Prerequisites

- Backend tunnel URL is live.
- Vercel account exists: <https://vercel.com>.
- Project is available locally in this workspace.

## Build Web Locally

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app
flutter pub get
flutter build web --release --no-wasm-dry-run --dart-define=UNIATTEND_API_BASE_URL=https://api.yourdomain.com
```

## Deploy to Vercel from Prebuilt Output

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app\build\web
npx --yes vercel --prod --yes .
```

## Verify After Deploy

- Open the Vercel URL and confirm login page loads.
- Check backend health through tunnel URL.
- Confirm browser requests are not blocked by CORS.

## CORS Requirement

Set backend allowed origins to include your Vercel URL:

```env
UNIATTEND_CORS_ORIGINS=https://your-app.vercel.app,https://api.yourdomain.com,http://localhost:3000,http://localhost:5173
```

Restart backend after updating env.

## iPhone Use

- Open the Vercel URL in Safari.
- Use Share, then Add to Home Screen.

## Quick Troubleshooting

| Issue | Fix |
| --- | --- |
| Web app loads but API fails | Verify UNIATTEND_API_BASE_URL used at build time |
| CORS errors in browser | Add exact Vercel origin in UNIATTEND_CORS_ORIGINS |
| Tunnel not reachable | Keep backend and cloudflared processes running |
| Old web behavior | Force refresh and redeploy |

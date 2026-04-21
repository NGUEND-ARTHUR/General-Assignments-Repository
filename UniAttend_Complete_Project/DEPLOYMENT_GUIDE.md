# UniAttend Deployment Guide

This guide covers remote backend access, web deployment for iPhone users, and APK builds.

## Phase 1: Expose Backend Publicly (Cloudflare Tunnel)

### Why

Your backend on your computer is only reachable on your local network. A tunnel gives it a public HTTPS endpoint.

### Prerequisites

- Cloudflare account: <https://dash.cloudflare.com>
- A domain managed in Cloudflare (for permanent named tunnel)

### Step 1.1 Install Cloudflared

```cmd
winget install --id Cloudflare.cloudflared -e --accept-package-agreements --accept-source-agreements
```

If not in PATH, use direct binary:

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" --version
```

### Step 1.2 Login

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel login
```

### Step 1.3 Create Named Tunnel

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel create uniattend-backend
```

### Step 1.4 Route DNS

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel route dns uniattend-backend api.yourdomain.com
```

### Step 1.5 Create Config

Create file at `C:\Users\<you>\.cloudflared\config.yml`:

```yaml
tunnel: uniattend-backend
credentials-file: C:\Users\<you>\.cloudflared\<TUNNEL_UUID>.json
ingress:
  - hostname: api.yourdomain.com
    service: http://127.0.0.1:8000
  - service: http_status:404
```

### Step 1.6 Run Tunnel

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel run uniattend-backend
```

## Phase 2: Backend CORS

Update backend env so browser requests from Vercel are accepted:

```env
UNIATTEND_CORS_ORIGINS=https://your-app.vercel.app,https://api.yourdomain.com,http://localhost:3000,http://localhost:5173
```

Restart backend:

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Phase 3: Build and Deploy Flutter Web

Build with backend URL:

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app
flutter build web --release --no-wasm-dry-run --dart-define=UNIATTEND_API_BASE_URL=https://api.yourdomain.com
```

Deploy prebuilt files:

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app\build\web
npx --yes vercel --prod --yes
```

## Phase 4: iPhone Access

- Open your Vercel URL in Safari
- Tap Share, then Add to Home Screen

## Phase 5: Build Android APK

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app
flutter build apk --release --dart-define=UNIATTEND_API_BASE_URL=https://api.yourdomain.com
```

Output APK:

- `flutter_app\build\app\outputs\flutter-apk\app-release.apk`

## Troubleshooting

### Tunnel URL not reachable

- Keep backend terminal running
- Keep cloudflared terminal running
- Verify DNS points to the tunnel

### CORS error in browser

- Add exact Vercel origin in `UNIATTEND_CORS_ORIGINS`
- Restart backend

### APK cannot connect

- Rebuild APK with current backend URL
- Ensure backend and tunnel are running

## Cost

| Component | Cost |
| --- | --- |
| Cloudflare Tunnel | Free |
| Vercel Hosting | Free tier |
| Domain | Usually low yearly cost |
| PostgreSQL (future) | Free tiers available |

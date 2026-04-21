# UniAttend Web Deploy Now (CMD)

Use this sequence to finish web deployment from Windows Command Prompt.

## 1) Build Flutter Web with your real backend URL

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app
flutter pub get
flutter build web --release --no-wasm-dry-run --dart-define=UNIATTEND_API_BASE_URL=https://uniattend-backend.yourdomain.com
```

Replace `https://uniattend-backend.yourdomain.com` with your real Cloudflare tunnel/domain URL.

## 2) Quick local verification

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app\build\web
python -m http.server 8080
```

Open `http://localhost:8080` and verify login page loads.

## 3) Deploy to Vercel from prebuilt output (most reliable)

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app\build\web
npx vercel deploy --prod
```

Notes:

- First run will ask for Vercel login and project link.
- Deploying from `build\web` serves static files directly.
- This avoids CI build failures if Flutter is not available in Vercel build image.

## 4) Post-deploy checks

1. Open your Vercel URL on desktop browser.
2. Test login and course listing.
3. Open same URL on iPhone Safari.
4. Add to Home Screen.

## 5) Backend CORS must include your Vercel URL

In backend `.env`:

```env
UNIATTEND_CORS_ORIGINS=https://YOUR-VERCEL-URL.vercel.app,https://uniattend-backend.yourdomain.com,http://localhost:3000,http://localhost:5173
```

Restart backend after editing.

## 6) Health check

```cmd
curl https://uniattend-backend.yourdomain.com/health
```

Expected:

```json
{"ok":true,"service":"uniattend-backend"}
```

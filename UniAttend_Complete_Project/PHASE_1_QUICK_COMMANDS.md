# UniAttend Phase 1 Quick Commands (Windows CMD)

## 1. Verify Cloudflared

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" --version
```

## 2. Login to Cloudflare

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel login
```

## 3. Create Tunnel

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel create uniattend-backend
```

## 4. Create DNS Route

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel route dns uniattend-backend api.yourdomain.com
```

## 5. Start Backend

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## 6. Start Tunnel

```cmd
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel run uniattend-backend
```

## 7. Verify Public Health

```cmd
curl https://api.yourdomain.com/health
```

Expected response:

```json
{"ok":true,"service":"uniattend-backend"}
```

## 8. Build Web and APK

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\flutter_app
flutter build web --release --dart-define=UNIATTEND_API_BASE_URL=https://api.yourdomain.com
flutter build apk --release --dart-define=UNIATTEND_API_BASE_URL=https://api.yourdomain.com
```

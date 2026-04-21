# Playwright MVP - Diplomax Contract and Web Flows

MVP coverage includes:
- Backend contract checks (`api-deployed` and optional `api-local`)
- Auth flow checks for student, university, recruiter
- Protected endpoint checks after successful auth
- UI smoke checks for admin, student, university, recruiter web apps

## 1) Install dependencies

```cmd
cd /d C:\Users\Nguend Arthur Johann\Desktop\General-Assignments-Repository\diplomax_cm\playwright-mvp
npm install
```

## 2) Install Playwright browsers (required for e2e projects)

```cmd
npx playwright install
```

## 3) Configure environment

```cmd
set API_BASE_URL=https://diplomax-backend.onrender.com
set RUN_LOCAL_API=0
set RUN_DEPLOYED_API=1
set RUN_STRICT_AUTH=0
```

Optional seeded-password checks:

```cmd
set STUDENT_PASSWORD=<DEFAULT_STUDENT_PASSWORD>
set UNIVERSITY_PASSWORD=<DEFAULT_ICT_ADMIN_PASSWORD>
```

Optional web app URLs for e2e smoke tests:

```cmd
set ADMIN_WEB_URL=http://127.0.0.1:8080
set STUDENT_WEB_URL=http://127.0.0.1:8081
set UNIVERSITY_WEB_URL=http://127.0.0.1:8082
set RECRUITER_WEB_URL=http://127.0.0.1:8083
```

## 4) Run tests

```cmd
npm test
```

## Notes
- `API_BASE_URL` and `LOCAL_API_BASE_URL` must not include `/v1`.
- Local backend tests are opt-in (`RUN_LOCAL_API=1`).
- Student/university positive protected tests are skipped if passwords are not set.
- UI tests skip when an app URL is unreachable, but still require Playwright browser binaries.

# UniAttend Playwright MVP Tests

This suite validates:

- Backend endpoint health and contract behavior.
- End-user role workflows (lecturer, student, admin) through the API.

## Coverage

- `/health`
- `/auth/register`, `/auth/login`, `/auth/me`
- `/courses`
- `/sessions` (create, update, detail, list per course, active)
- `/attendance/checkin`, `/attendance/checkout`
- `/attendance/session/{session_id}`, `/attendance/me`

## Run (Windows cmd)

```cmd
cd /d c:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\backend\playwright-mvp
npm install
npm test
```

## Notes

- Tests auto-start the FastAPI server with seeded data using the backend virtual environment.
- Default base URL is `http://127.0.0.1:8000`.
- The suite uses unique values where needed to avoid collisions across repeated runs.

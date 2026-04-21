# UniAttend Backend + Database

This folder contains a FastAPI backend and SQLite database for UniAttend.

## What is included

- REST API for auth, courses, sessions, and attendance.
- SQLite database schema in `sql/schema.sql`.
- Bootstrap admin and super-admin account initialization via environment variables.

## Quick start (Windows cmd)

```cmd
cd /d c:\Users\Nguend Arthur Johann\Desktop\UniAttend_Complete_Project\backend
py -3 -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
py -3 -m app.init_db
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```cmd
curl http://127.0.0.1:8000/health
```

Swagger docs:

- <http://127.0.0.1:8000/docs>

## Bootstrap accounts

The backend does not create demo/mock users or courses.

At startup it ensures:

- admin account from `UNIATTEND_ADMIN_*` environment variables
- super admin account from `UNIATTEND_SUPER_ADMIN_*` environment variables

## Environment variables

Copy `.env.example` values into your deployment environment:

- `UNIATTEND_DB_PATH`
- `UNIATTEND_JWT_SECRET`
- `UNIATTEND_TOKEN_EXPIRE_MINUTES`

## API summary

- `POST /auth/register`
- `POST /auth/login`
- `GET /courses`
- `POST /sessions`
- `POST /attendance/checkin`
- `POST /attendance/checkout`
- `GET /attendance/session/{session_id}`

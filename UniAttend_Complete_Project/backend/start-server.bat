@echo off
setlocal enabledelayedexpansion

REM Set environment variables
set UNIATTEND_DATABASE_URL=postgresql://postgres@127.0.0.1:5432/uniattend
set UNIATTEND_POSTGRES_PASSWORD=Arthur@237
set UNIATTEND_POSTGRES_HOST=127.0.0.1
set UNIATTEND_POSTGRES_PORT=5432
set UNIATTEND_POSTGRES_DB=uniattend
set UNIATTEND_POSTGRES_USER=postgres

REM Initialize database and start server
.\.venv\Scripts\python.exe -m app.init_db
if errorlevel 1 (
    echo Database initialization failed
    exit /b 1
)

.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000

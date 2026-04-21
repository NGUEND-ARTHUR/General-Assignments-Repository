#!/usr/bin/env python3
import os
import sys

# Set environment variables directly in this process
# Don't set DATABASE_URL - let _build_connection_kwargs() use individual vars
os.environ.pop('UNIATTEND_DATABASE_URL', None)
os.environ.pop('DATABASE_URL', None)

os.environ['UNIATTEND_POSTGRES_PASSWORD'] = 'Arthur@237'
os.environ['UNIATTEND_POSTGRES_HOST'] = '127.0.0.1'
os.environ['UNIATTEND_POSTGRES_PORT'] = '5432'
os.environ['UNIATTEND_POSTGRES_DB'] = 'uniattend'
os.environ['UNIATTEND_POSTGRES_USER'] = 'postgres'

print("=" * 60, file=sys.stderr)
print("Environment variables set:", file=sys.stderr)
print(f"  DATABASE_URL: {os.environ.get('UNIATTEND_DATABASE_URL')}", file=sys.stderr)
print(f"  POSTGRES_PASSWORD: {os.environ.get('UNIATTEND_POSTGRES_PASSWORD')}", file=sys.stderr)
print(f"  POSTGRES_HOST: {os.environ.get('UNIATTEND_POSTGRES_HOST')}", file=sys.stderr)
print(f"  POSTGRES_USER: {os.environ.get('UNIATTEND_POSTGRES_USER')}", file=sys.stderr)
print(f"  POSTGRES_DB: {os.environ.get('UNIATTEND_POSTGRES_DB')}", file=sys.stderr)
print(f"  POSTGRES_PORT: {os.environ.get('UNIATTEND_POSTGRES_PORT')}", file=sys.stderr)
print("=" * 60, file=sys.stderr)

# Initialize database
print("\n[1/2] Initializing database...", file=sys.stderr)
try:
    from app.db import init_db
    init_db()
    print("[OK] Database initialized", file=sys.stderr)
except Exception as e:
    print(f"[ERROR] Database initialization failed: {e}", file=sys.stderr)
    sys.exit(1)

# Start uvicorn server
print("\n[2/2] Starting server...", file=sys.stderr)
import uvicorn
uvicorn.run('app.main:app', host='127.0.0.1', port=8000)

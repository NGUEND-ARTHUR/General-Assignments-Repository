import os
import psycopg2
from pathlib import Path

for env_file in [Path('.env'), Path('.env.local')]:
    if env_file.exists():
        for raw in env_file.read_text(encoding='utf-8').splitlines():
            line = raw.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, v = line.split('=', 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            os.environ.setdefault(k, v)

ids = [
    ("u_admin_default", "users"),
    ("u_student_default", "users"),
    ("u_lecturer_default", "users"),
    ("u_course_rep_default", "users"),
    ("course_demo_1", "courses"),
    ("session_demo_1", "attendance_sessions"),
]

dsn = os.getenv("UNIATTEND_DATABASE_URL") or os.getenv("DATABASE_URL")
kwargs = {}
if dsn:
    kwargs["dsn"] = dsn.replace("+asyncpg", "").replace("+psycopg", "")
else:
    kwargs = {
        "host": os.getenv("UNIATTEND_POSTGRES_HOST", "127.0.0.1"),
        "port": int(os.getenv("UNIATTEND_POSTGRES_PORT", "5432")),
        "dbname": os.getenv("UNIATTEND_POSTGRES_DB", "uniattend"),
        "user": os.getenv("UNIATTEND_POSTGRES_USER", "postgres"),
        "password": os.getenv("UNIATTEND_POSTGRES_PASSWORD") or os.getenv("PGPASSWORD"),
        "connect_timeout": int(os.getenv("UNIATTEND_POSTGRES_CONNECT_TIMEOUT", "5")),
    }

conn = psycopg2.connect(**kwargs)
cur = conn.cursor()
for id_value, table in ids:
    cur.execute(f"SELECT EXISTS(SELECT 1 FROM {table} WHERE id=%s)", (id_value,))
    print(f"{id_value}\texists={cur.fetchone()[0]}")

cur.execute("SELECT COUNT(*) FROM users WHERE role='super_admin'")
print(f"super_admin_count={cur.fetchone()[0]}")
cur.close()
conn.close()

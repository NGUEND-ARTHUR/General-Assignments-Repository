from __future__ import annotations

import os
import re
import sqlite3
from datetime import datetime
import uuid
from pathlib import Path
from typing import Any, Iterable

import psycopg2
from psycopg2.extras import RealDictCursor

from app.security import hash_password

BASE_DIR = Path(__file__).resolve().parent.parent
SQLITE_DB_PATH = Path(os.getenv("UNIATTEND_SQLITE_DB_PATH", BASE_DIR / "data" / "uniattend.db"))
SCHEMA_PATH = BASE_DIR / "sql" / "schema.sql"

TABLE_ORDER = [
    "users",
    "role_applications",
    "courses",
    "course_enrollments",
    "attendance_sessions",
    "device_bindings",
    "attendance_records",
    "attendance_manual_actions",
    "attendance_anomalies",
]

TABLE_COLUMNS: dict[str, list[str]] = {
    "users": [
        "id",
        "full_name",
        "email",
        "password_hash",
        "matric_number",
        "department",
        "phone_number",
        "role",
        "created_at",
        "is_active",
        "blocked_at",
        "blocked_reason",
    ],
    "role_applications": [
        "id",
        "user_id",
        "requested_role",
        "status",
        "justification",
        "reviewed_by",
        "reviewed_at",
        "created_at",
    ],
    "courses": [
        "id",
        "course_code",
        "course_name",
        "lecturer_id",
        "lecturer_display_name",
        "course_rep_id",
        "semester",
        "academic_year",
    ],
    "course_enrollments": ["id", "course_id", "student_id", "created_at"],
    "attendance_sessions": [
        "id",
        "course_id",
        "class_type",
        "scheduled_date",
        "status",
        "check_in_opened_at",
        "check_out_opened_at",
        "classroom_latitude",
        "classroom_longitude",
        "created_by",
        "created_at",
    ],
    "device_bindings": ["id", "user_id", "device_id", "created_at"],
    "attendance_records": [
        "id",
        "session_id",
        "student_id",
        "check_in_time",
        "check_out_time",
        "check_in_latitude",
        "check_in_longitude",
        "check_out_latitude",
        "check_out_longitude",
        "device_id",
        "status",
        "created_at",
        "updated_at",
    ],
    "attendance_manual_actions": ["id", "session_id", "student_id", "added_by", "reason", "created_at"],
    "attendance_anomalies": ["id", "session_id", "student_id", "flagged_by", "reason", "details", "created_at"],
}


class QueryResult:
    def __init__(self, rows: Iterable[dict[str, Any]] | None = None, rowcount: int = -1) -> None:
        self._rows = list(rows or [])
        self.rowcount = rowcount
        self.lastrowid = None
        self.description = None

    def fetchone(self):
        return self._rows[0] if self._rows else None

    def fetchall(self):
        return list(self._rows)

    def __iter__(self):
        return iter(self._rows)


class PostgresConnection:
    def __init__(self, connection) -> None:
        self._connection = connection
        self.row_factory = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        if exc_type is None:
            self.commit()
        else:
            self.rollback()
        self.close()
        return False

    def close(self) -> None:
        self._connection.close()

    def commit(self) -> None:
        self._connection.commit()

    def rollback(self) -> None:
        self._connection.rollback()

    def cursor(self):
        return self._connection.cursor(cursor_factory=RealDictCursor)

    def execute(self, sql: str, params: Iterable[Any] | None = None) -> QueryResult:
        translated = _translate_sql(sql)
        if translated is None:
            return QueryResult()

        cursor = self._connection.cursor(cursor_factory=RealDictCursor)
        cursor.execute(translated, _normalize_params(params))
        rows = cursor.fetchall() if cursor.description else []
        rowcount = cursor.rowcount
        cursor.close()
        return QueryResult(rows, rowcount=rowcount)

    def executemany(self, sql: str, seq_of_params: Iterable[Iterable[Any]]) -> QueryResult:
        result = QueryResult()
        for params in seq_of_params:
            result = self.execute(sql, params)
        return result

    def executescript(self, script: str) -> None:
        for statement in _split_script(script):
            translated = _translate_sql(statement)
            if translated is None:
                continue
            self.execute(translated)


def _normalize_params(params: Iterable[Any] | None):
    if params is None:
        return ()
    if isinstance(params, tuple):
        return params
    if isinstance(params, list):
        return tuple(params)
    return params


def _split_script(script: str) -> list[str]:
    statements: list[str] = []
    for chunk in script.split(";"):
        statement = chunk.strip()
        if statement:
            statements.append(statement)
    return statements


def _translate_sql(sql: str) -> str | None:
    statement = sql.strip()
    if not statement:
        return None
    if statement.upper().startswith("PRAGMA"):
        return None

    if re.search(r"\bINSERT\s+OR\s+IGNORE\s+INTO\b", statement, flags=re.IGNORECASE):
        statement = re.sub(
            r"\bINSERT\s+OR\s+IGNORE\s+INTO\b",
            "INSERT INTO",
            statement,
            flags=re.IGNORECASE,
        )
        if "ON CONFLICT" not in statement.upper():
            statement = statement.rstrip(";") + " ON CONFLICT DO NOTHING"

    if "GROUP BY c.id" in statement and "COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name" in statement:
        statement = statement.replace(
            "COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name",
            "MAX(COALESCE(c.lecturer_display_name, l.full_name)) AS lecturer_name",
        )

    return statement.replace("?", "%s")


def _build_connection_kwargs() -> dict[str, Any]:
    dsn = os.getenv("UNIATTEND_DATABASE_URL") or os.getenv("DATABASE_URL")
    if dsn:
        return {"dsn": dsn}

    password = os.getenv("UNIATTEND_POSTGRES_PASSWORD") or os.getenv("PGPASSWORD")
    if not password:
        raise RuntimeError(
            "PostgreSQL password missing. Set UNIATTEND_POSTGRES_PASSWORD or DATABASE_URL."
        )

    return {
        "host": os.getenv("UNIATTEND_POSTGRES_HOST", "127.0.0.1"),
        "port": int(os.getenv("UNIATTEND_POSTGRES_PORT", "5432")),
        "dbname": os.getenv("UNIATTEND_POSTGRES_DB", "uniattend"),
        "user": os.getenv("UNIATTEND_POSTGRES_USER", "postgres"),
        "password": password,
        "connect_timeout": int(os.getenv("UNIATTEND_POSTGRES_CONNECT_TIMEOUT", "5")),
    }


def get_conn() -> PostgresConnection:
    connection = psycopg2.connect(**_build_connection_kwargs())
    return PostgresConnection(connection)


def init_db() -> None:
    schema_sql = _load_schema_sql()
    with get_conn() as conn:
        conn.executescript(schema_sql)
        _import_sqlite_snapshot_if_needed(conn)
        _ensure_super_admin(conn)
        _remove_seed_demo_data(conn)
        conn.commit()


def _load_schema_sql() -> str:
    lines = []
    for line in SCHEMA_PATH.read_text(encoding="utf-8").splitlines():
        if line.strip().upper().startswith("PRAGMA "):
            continue
        lines.append(line)
    return "\n".join(lines)


def _import_sqlite_snapshot_if_needed(conn: PostgresConnection) -> None:
    if not SQLITE_DB_PATH.exists():
        return

    existing_users = conn.execute("SELECT COUNT(*) AS count FROM users").fetchone()
    if existing_users and int(existing_users["count"] or 0) > 0:
        return

    with sqlite3.connect(SQLITE_DB_PATH) as source:
        source.row_factory = sqlite3.Row
        for table_name in TABLE_ORDER:
            available_columns = _sqlite_table_columns(source, table_name)
            if not available_columns:
                continue

            insert_columns = [
                column for column in TABLE_COLUMNS[table_name] if column in available_columns
            ]
            if not insert_columns:
                continue

            rows = source.execute(f"SELECT * FROM {table_name}").fetchall()
            if not rows:
                continue

            column_sql = ", ".join(insert_columns)
            placeholders = ", ".join(["%s"] * len(insert_columns))
            insert_sql = f"INSERT INTO {table_name} ({column_sql}) VALUES ({placeholders})"

            for row in rows:
                values = [row[column] for column in insert_columns]
                conn.execute(insert_sql, values)


def _sqlite_table_columns(source: sqlite3.Connection, table_name: str) -> set[str]:
    try:
        info = source.execute(f"PRAGMA table_info({table_name})").fetchall()
    except sqlite3.Error:
        return set()
    return {row[1] for row in info}


def _ensure_super_admin(conn: PostgresConnection) -> None:
    email = os.getenv("UNIATTEND_SUPER_ADMIN_EMAIL", "nguend.johann@ictuniversity.edu.cm").lower()
    password = os.getenv("UNIATTEND_SUPER_ADMIN_PASSWORD", "Arthur@ictu2024")
    full_name = os.getenv("UNIATTEND_SUPER_ADMIN_NAME", "Nguend Arthur Johann")
    matric_number = os.getenv("UNIATTEND_SUPER_ADMIN_MATRIC", "SUPERADMIN001")
    department = os.getenv("UNIATTEND_SUPER_ADMIN_DEPARTMENT", "ICT")
    phone = os.getenv("UNIATTEND_SUPER_ADMIN_PHONE", "+237000000000")

    existing = conn.execute("SELECT id FROM users WHERE lower(email) = %s", (email,)).fetchone()
    if existing:
        conn.execute(
            "DELETE FROM users WHERE role = 'super_admin' AND id != %s",
            (existing["id"],),
        )
        conn.execute(
            """
            UPDATE users
            SET full_name = %s,
                password_hash = %s,
                matric_number = %s,
                department = %s,
                phone_number = %s,
                role = 'super_admin',
                email = %s,
                is_active = 1,
                blocked_at = NULL,
                blocked_reason = NULL
            WHERE id = %s
            """,
            (
                full_name,
                hash_password(password),
                matric_number,
                department,
                phone,
                email,
                existing["id"],
            ),
        )
        return

    # No super admin with target email: keep only one existing super admin if present.
    any_super = conn.execute(
        "SELECT id FROM users WHERE role = 'super_admin' ORDER BY created_at ASC LIMIT 1"
    ).fetchone()
    if any_super:
        conn.execute(
            "DELETE FROM users WHERE role = 'super_admin' AND id != %s",
            (any_super["id"],),
        )
        conn.execute(
            """
            UPDATE users
            SET full_name = %s,
                email = %s,
                password_hash = %s,
                matric_number = %s,
                department = %s,
                phone_number = %s,
                role = 'super_admin',
                is_active = 1,
                blocked_at = NULL,
                blocked_reason = NULL
            WHERE id = %s
            """,
            (
                full_name,
                email,
                hash_password(password),
                matric_number,
                department,
                phone,
                any_super["id"],
            ),
        )
        return

    conn.execute(
        """
        INSERT INTO users
        (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, 'super_admin', CURRENT_TIMESTAMP)
        """,
        (
            "u_super_admin_default",
            full_name,
            email,
            hash_password(password),
            matric_number,
            department,
            phone,
        ),
    )


def _remove_seed_demo_data(conn: PostgresConnection) -> None:
    seeded_user_ids = [
        "u_admin_default",
        "u_student_default",
        "u_lecturer_default",
        "u_course_rep_default",
    ]
    seeded_course_ids = ["course_demo_1"]
    seeded_session_ids = ["session_demo_1"]

    def _in_clause(values: list[str]) -> str:
        return ",".join(["%s"] * len(values))

    user_clause = _in_clause(seeded_user_ids)
    course_clause = _in_clause(seeded_course_ids)
    session_clause = _in_clause(seeded_session_ids)

    demo_course_rows = conn.execute(
        f"""
        SELECT id FROM courses
        WHERE id IN ({course_clause})
           OR lecturer_id IN ({user_clause})
           OR course_rep_id IN ({user_clause})
        """,
        tuple(seeded_course_ids + seeded_user_ids + seeded_user_ids),
    ).fetchall()
    demo_course_ids = sorted({row["id"] for row in demo_course_rows})

    demo_session_ids: list[str] = []
    if demo_course_ids:
        session_rows = conn.execute(
            f"""
            SELECT id FROM attendance_sessions
            WHERE id IN ({session_clause})
               OR course_id IN ({_in_clause(demo_course_ids)})
               OR created_by IN ({user_clause})
            """,
            tuple(seeded_session_ids + demo_course_ids + seeded_user_ids),
        ).fetchall()
        demo_session_ids = sorted({row["id"] for row in session_rows})
    else:
        session_rows = conn.execute(
            f"""
            SELECT id FROM attendance_sessions
            WHERE id IN ({session_clause})
               OR created_by IN ({user_clause})
            """,
            tuple(seeded_session_ids + seeded_user_ids),
        ).fetchall()
        demo_session_ids = sorted({row["id"] for row in session_rows})

    if demo_session_ids:
        session_ids_clause = _in_clause(demo_session_ids)
        conn.execute(
            f"DELETE FROM attendance_manual_actions WHERE session_id IN ({session_ids_clause})",
            tuple(demo_session_ids),
        )
        conn.execute(
            f"DELETE FROM attendance_anomalies WHERE session_id IN ({session_ids_clause})",
            tuple(demo_session_ids),
        )
        conn.execute(
            f"DELETE FROM attendance_records WHERE session_id IN ({session_ids_clause})",
            tuple(demo_session_ids),
        )
        conn.execute(
            f"DELETE FROM attendance_sessions WHERE id IN ({session_ids_clause})",
            tuple(demo_session_ids),
        )

    if demo_course_ids:
        course_ids_clause = _in_clause(demo_course_ids)
        conn.execute(
            f"DELETE FROM course_enrollments WHERE course_id IN ({course_ids_clause})",
            tuple(demo_course_ids),
        )
        conn.execute(
            f"DELETE FROM courses WHERE id IN ({course_ids_clause})",
            tuple(demo_course_ids),
        )

    conn.execute(
        f"DELETE FROM attendance_manual_actions WHERE added_by IN ({user_clause})",
        tuple(seeded_user_ids),
    )
    conn.execute(
        f"DELETE FROM attendance_anomalies WHERE flagged_by IN ({user_clause})",
        tuple(seeded_user_ids),
    )
    conn.execute(
        f"DELETE FROM attendance_records WHERE student_id IN ({user_clause})",
        tuple(seeded_user_ids),
    )
    conn.execute(
        f"DELETE FROM device_bindings WHERE user_id IN ({user_clause})",
        tuple(seeded_user_ids),
    )
    conn.execute(
        f"DELETE FROM role_applications WHERE user_id IN ({user_clause}) OR reviewed_by IN ({user_clause})",
        tuple(seeded_user_ids + seeded_user_ids),
    )
    conn.execute(
        f"DELETE FROM course_enrollments WHERE student_id IN ({user_clause})",
        tuple(seeded_user_ids),
    )
    conn.execute(
        f"DELETE FROM users WHERE id IN ({user_clause})",
        tuple(seeded_user_ids),
    )

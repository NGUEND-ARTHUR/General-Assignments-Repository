import base64
import hashlib
import hmac
import json
import math
import os
import uuid
from datetime import datetime

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from jose import jwt, JWTError

from app.db import get_conn, init_db
from app.models import (
    AttendanceAnomalyRequest,
    AdminUserBlockRequest,
    AdminUserUpdateRequest,
    CheckRequest,
    CourseCreateRequest,
    LoginRequest,
    ManualAttendanceRequest,
    RoleApplicationActionRequest,
    RegisterRequest,
    SessionCreateRequest,
)
from app.security import JWT_ALGORITHM, JWT_SECRET, create_access_token, hash_password, verify_password

app = FastAPI(title="UniAttend Backend", version="1.0.0")
QR_ROTATION_SECONDS = int(os.getenv("UNIATTEND_QR_ROTATION_SECONDS", "30"))
QR_SECRET = os.getenv("UNIATTEND_QR_SECRET", JWT_SECRET)
MIN_CHECKOUT_DELAY_SECONDS = int(os.getenv("UNIATTEND_MIN_CHECKOUT_DELAY_SECONDS", "900"))
DEFAULT_CORS_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]


def _load_cors_origins() -> list[str]:
    raw = os.getenv("UNIATTEND_CORS_ORIGINS", "")
    origins = [origin.strip() for origin in raw.split(",") if origin.strip()]
    if origins:
        return origins
    return DEFAULT_CORS_ORIGINS


app.add_middleware(
    CORSMiddleware,
    allow_origins=_load_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup() -> None:
    init_db()


def _require_user(authorization: str | None = Header(default=None)) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = payload["sub"]
        role = payload["role"]
        with get_conn() as conn:
            row = conn.execute(
                "SELECT id, is_active FROM users WHERE id = ?",
                (user_id,),
            ).fetchone()
        if not row:
            raise HTTPException(status_code=401, detail="Invalid token")
        if int(row["is_active"] or 0) != 1:
            raise HTTPException(status_code=403, detail="This account is blocked")
        return {"user_id": user_id, "role": role}
    except (JWTError, KeyError):
        raise HTTPException(status_code=401, detail="Invalid token")


def _user_payload(row) -> dict:
    return {
        "id": row["id"],
        "full_name": row["full_name"],
        "email": row["email"],
        "matric_number": row["matric_number"],
        "department": row["department"],
        "phone_number": row["phone_number"],
        "role": row["role"],
        "created_at": row["created_at"],
        "is_active": int(row["is_active"] or 0) == 1 if "is_active" in row.keys() else True,
        "blocked_at": row["blocked_at"] if "blocked_at" in row.keys() else None,
        "blocked_reason": row["blocked_reason"] if "blocked_reason" in row.keys() else None,
    }


def _admin_user_payload(row) -> dict:
    return _user_payload(row)


def _qr_window() -> int:
    return int(datetime.utcnow().timestamp()) // QR_ROTATION_SECONDS


def _qr_signature(session_id: str, course_id: str, phase: str, window: int) -> str:
    raw = f"{session_id}:{course_id}:{phase}:{window}".encode("utf-8")
    digest = hmac.new(QR_SECRET.encode("utf-8"), raw, hashlib.sha256).hexdigest()
    return digest[:24]


def _build_qr_payload(session_id: str, course_id: str, phase: str, window: int | None = None) -> str:
    current_window = _qr_window() if window is None else window
    payload = {
        "sessionId": session_id,
        "courseId": course_id,
        "phase": phase,
        "window": current_window,
        "signature": _qr_signature(session_id, course_id, phase, current_window),
    }
    return base64.urlsafe_b64encode(
        json.dumps(payload, separators=(",", ":")).encode("utf-8")
    ).decode("ascii")


def _validate_qr_payload(
    raw_payload: str,
    *,
    expected_session_id: str,
    expected_course_id: str,
    expected_phase: str,
) -> None:
    try:
        decoded = base64.urlsafe_b64decode(raw_payload.encode("ascii")).decode("utf-8")
        payload = json.loads(decoded)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid QR code payload")

    session_id = str(payload.get("sessionId") or "")
    course_id = str(payload.get("courseId") or "")
    phase = str(payload.get("phase") or "")
    window = payload.get("window")
    signature = str(payload.get("signature") or "")

    if not session_id or not course_id or phase != expected_phase:
        raise HTTPException(status_code=400, detail="This QR code is not for the current attendance phase")
    if session_id != expected_session_id or course_id != expected_course_id:
        raise HTTPException(status_code=400, detail="This QR code is for another session")
    if not isinstance(window, int):
        raise HTTPException(status_code=400, detail="Invalid QR code window")
    if abs(_qr_window() - window) > 1:
        raise HTTPException(status_code=400, detail="QR code expired")
    expected_signature = _qr_signature(session_id, course_id, phase, window)
    if not hmac.compare_digest(signature, expected_signature):
        raise HTTPException(status_code=400, detail="Invalid QR code signature")


def _get_admin_user_rows(conn, role: str | None = None):
    query = """
        SELECT id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at,
               is_active, blocked_at, blocked_reason
        FROM users
        WHERE role != 'super_admin'
    """
    params: list[str] = []
    if role:
        query += " AND role = ?"
        params.append(role)
    query += " ORDER BY role ASC, full_name ASC"
    return conn.execute(query, params).fetchall()


def _delete_user_with_dependents(conn, user_id: str) -> None:
    courses = conn.execute("SELECT id FROM courses WHERE lecturer_id = ?", (user_id,)).fetchall()
    course_ids = [row["id"] for row in courses]
    if course_ids:
        placeholders = ",".join("?" for _ in course_ids)
        session_rows = conn.execute(
            f"SELECT id FROM attendance_sessions WHERE course_id IN ({placeholders})",
            course_ids,
        ).fetchall()
        session_ids = [row["id"] for row in session_rows]
        if session_ids:
            sp = ",".join("?" for _ in session_ids)
            conn.execute(f"DELETE FROM attendance_manual_actions WHERE session_id IN ({sp})", session_ids)
            conn.execute(f"DELETE FROM attendance_records WHERE session_id IN ({sp})", session_ids)
            conn.execute(f"DELETE FROM attendance_sessions WHERE id IN ({sp})", session_ids)
        conn.execute(f"DELETE FROM course_enrollments WHERE course_id IN ({placeholders})", course_ids)
        conn.execute(f"DELETE FROM courses WHERE id IN ({placeholders})", course_ids)

    conn.execute("DELETE FROM attendance_manual_actions WHERE added_by = ?", (user_id,))
    conn.execute("DELETE FROM attendance_records WHERE student_id = ?", (user_id,))
    conn.execute("DELETE FROM attendance_sessions WHERE created_by = ?", (user_id,))
    conn.execute("DELETE FROM course_enrollments WHERE student_id = ?", (user_id,))
    conn.execute("UPDATE courses SET course_rep_id = NULL WHERE course_rep_id = ?", (user_id,))
    conn.execute("DELETE FROM role_applications WHERE user_id = ?", (user_id,))
    conn.execute("DELETE FROM role_applications WHERE reviewed_by = ?", (user_id,))
    conn.execute("DELETE FROM device_bindings WHERE user_id = ?", (user_id,))
    conn.execute("DELETE FROM users WHERE id = ?", (user_id,))


def _distance_meters(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    radius_m = 6371000.0
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )
    return 2 * radius_m * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _ensure_session_within_radius(session_row, latitude: float, longitude: float) -> None:
    classroom_lat = session_row["classroom_latitude"]
    classroom_lon = session_row["classroom_longitude"]
    if classroom_lat is None or classroom_lon is None:
        raise HTTPException(status_code=400, detail="Session classroom location is not set")

    distance = _distance_meters(latitude, longitude, float(classroom_lat), float(classroom_lon))
    if distance > 50.0:
        raise HTTPException(status_code=403, detail="You must be within 50 meters of the classroom to register attendance")


def _ensure_device_not_used_by_other_student(conn, session_id: str, student_id: str, device_id: str) -> None:
    existing = conn.execute(
        "SELECT student_id FROM attendance_records WHERE session_id = ? AND device_id = ?",
        (session_id, device_id),
    ).fetchone()
    if existing and existing["student_id"] != student_id:
        raise HTTPException(status_code=409, detail="This phone already marked attendance for another student in this session")


def _ensure_device_bound_to_student(conn, student_id: str, device_id: str) -> None:
    binding = conn.execute(
        "SELECT user_id, device_id FROM device_bindings WHERE user_id = ?",
        (student_id,),
    ).fetchone()
    if binding:
        if binding["device_id"] != device_id:
            conn.execute(
                "UPDATE device_bindings SET device_id = ?, created_at = ? WHERE user_id = ?",
                (device_id, datetime.utcnow().isoformat(), student_id),
            )
        return

    device_owner = conn.execute(
        "SELECT user_id FROM device_bindings WHERE device_id = ?",
        (device_id,),
    ).fetchone()
    if device_owner and device_owner["user_id"] != student_id:
        raise HTTPException(
            status_code=409,
            detail="This device is already linked to another student account",
        )

    conn.execute(
        """
        INSERT INTO device_bindings (id, user_id, device_id, created_at)
        VALUES (?, ?, ?, ?)
        """,
        (f"db_{uuid.uuid4().hex[:10]}", student_id, device_id, datetime.utcnow().isoformat()),
    )


def _parse_iso_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def _ensure_checkout_window_openable(session_row) -> None:
    opened = _parse_iso_datetime(session_row["check_in_opened_at"])
    if not opened:
        raise HTTPException(status_code=409, detail="Check-in window is missing for this session")
    elapsed = (datetime.utcnow() - opened).total_seconds()
    if elapsed < MIN_CHECKOUT_DELAY_SECONDS:
        remaining = int(MIN_CHECKOUT_DELAY_SECONDS - elapsed)
        raise HTTPException(
            status_code=409,
            detail=f"Check-out cannot open yet. Try again in {remaining} seconds",
        )


def _ensure_super_admin(user: dict) -> None:
    if user["role"] != "super_admin":
        raise HTTPException(status_code=403, detail="Only the super admin can perform this action")


def _ensure_manageable_user_role(role: str) -> None:
    if role not in {"student", "course_rep", "lecturer", "admin", "super_admin"}:
        raise HTTPException(status_code=400, detail="Invalid user role")


def _course_payload_from_row(row, can_manage: bool) -> dict:
    item = dict(row)
    item["can_manage"] = can_manage
    return item


def _resolve_lecturer_identifier(conn, identifier: str) -> str | None:
    normalized = identifier.strip()
    if not normalized:
        return None

    row = conn.execute(
        """
        SELECT id
        FROM users
        WHERE id = ?
           OR lower(email) = lower(?)
           OR lower(full_name) = lower(?)
           OR lower(full_name) LIKE lower(?)
        """,
        (normalized, normalized, normalized, f"%{normalized}%"),
    ).fetchone()
    if not row or row["id"] is None:
        return None

    lecturer = conn.execute(
        "SELECT id FROM users WHERE id = ? AND role = 'lecturer'",
        (row["id"],),
    ).fetchone()
    return lecturer["id"] if lecturer else None


def _get_user_full_name(conn, user_id: str) -> str | None:
    row = conn.execute("SELECT full_name FROM users WHERE id = ?", (user_id,)).fetchone()
    return row["full_name"] if row else None


def _normalize_person_name(value: str) -> str:
    normalized = " ".join(value.strip().lower().replace(".", " ").split())
    tokens = [
        t for t in normalized.split(" ")
        if t and t not in {"mr", "mrs", "ms", "dr", "engr", "prof", "mme", "sir", "madam"}
    ]
    return " ".join(tokens)


def _names_compatible(name_a: str | None, name_b: str | None) -> bool:
    if not name_a or not name_b:
        return False

    a = _normalize_person_name(name_a)
    b = _normalize_person_name(name_b)
    if not a or not b:
        return False
    if a == b:
        return True

    # Fast path for substring compatibility
    if a in b or b in a:
        return True

    # Token-based fallback: match on any significant shared token
    # (e.g. "Engr. Tanwi" vs "TANWI" or "Arthur Tanwi").
    a_tokens = {t for t in a.split(" ") if len(t) >= 3}
    b_tokens = {t for t in b.split(" ") if len(t) >= 3}
    return len(a_tokens.intersection(b_tokens)) > 0


def _lecturer_name_matches_course(conn, user_id: str, course_id: str) -> bool:
    name = _get_user_full_name(conn, user_id)
    if not name:
        return False

    row = conn.execute(
        """
        SELECT lecturer_display_name
        FROM courses
        WHERE id = ?
        """,
        (course_id,),
    ).fetchone()
    if not row:
        return False

    return _names_compatible(row["lecturer_display_name"], name)


def _enroll_user_in_course(conn, user_id: str, course_id: str) -> None:
    conn.execute(
        """
        INSERT OR IGNORE INTO course_enrollments (id, course_id, student_id, created_at)
        VALUES (?, ?, ?, ?)
        """,
        (f"en_{uuid.uuid4().hex[:10]}", course_id, user_id, datetime.utcnow().isoformat()),
    )


def _unenroll_user_from_course(conn, user_id: str, course_id: str) -> None:
    conn.execute(
        "DELETE FROM course_enrollments WHERE course_id = ? AND student_id = ?",
        (course_id, user_id),
    )


def _can_access_course(conn, user: dict, course_id: str) -> bool:
    role = user["role"]
    if role in {"admin", "super_admin"}:
        return True

    if role == "lecturer":
        row = conn.execute(
            """
            SELECT id FROM courses
            WHERE id = ? AND lecturer_id = ?
            """,
            (course_id, user["user_id"]),
        ).fetchone()
        return row is not None or _lecturer_name_matches_course(conn, user["user_id"], course_id)

    if role == "course_rep":
        row = conn.execute(
            """
                        SELECT c.id
                        FROM courses c
                        LEFT JOIN course_enrollments e
                            ON e.course_id = c.id AND e.student_id = ?
                        WHERE c.id = ?
                            AND (c.course_rep_id = ? OR e.id IS NOT NULL)
            """,
                        (user["user_id"], course_id, user["user_id"]),
        ).fetchone()
        return row is not None

    row = conn.execute(
        """
        SELECT e.id
        FROM course_enrollments e
        WHERE e.course_id = ? AND e.student_id = ?
        """,
        (course_id, user["user_id"]),
    ).fetchone()
    return row is not None


def _ensure_course_access(conn, user: dict, course_id: str) -> None:
    if not _can_access_course(conn, user, course_id):
        raise HTTPException(status_code=403, detail="You do not have access to this course")


def _can_manage_course(conn, user: dict, course_id: str) -> bool:
    role = user["role"]
    if role in {"admin", "super_admin"}:
        return True
    if role == "lecturer":
        row = conn.execute(
            """
            SELECT id FROM courses
            WHERE id = ? AND lecturer_id = ?
            """,
            (course_id, user["user_id"]),
        ).fetchone()
        return row is not None or _lecturer_name_matches_course(conn, user["user_id"], course_id)

    if role == "course_rep":
        row = conn.execute(
            """
            SELECT id FROM courses
            WHERE id = ? AND course_rep_id = ?
            """,
            (course_id, user["user_id"]),
        ).fetchone()
        return row is not None

    return False


def _ensure_can_manage_course(conn, user: dict, course_id: str) -> None:
    if not _can_manage_course(conn, user, course_id):
        raise HTTPException(status_code=403, detail="You are not allowed to manage this course")


def _get_session_with_course(conn, session_id: str):
    return conn.execute(
        """
        SELECT s.*, c.id AS course_id_ref, c.lecturer_id, c.course_rep_id
        FROM attendance_sessions s
        INNER JOIN courses c ON c.id = s.course_id
        WHERE s.id = ?
        """,
        (session_id,),
    ).fetchone()


def _ensure_session_access(conn, user: dict, session_id: str):
    session = _get_session_with_course(conn, session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    _ensure_course_access(conn, user, session["course_id"])
    return session


def _ensure_can_manage_session(conn, user: dict, session_id: str):
    session = _get_session_with_course(conn, session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    _ensure_can_manage_course(conn, user, session["course_id"])
    return session


@app.get("/health")
def health() -> dict:
    return {"ok": True, "service": "uniattend-backend"}


@app.post("/auth/register")
def register(body: RegisterRequest) -> dict:
    user_id = f"u_{uuid.uuid4().hex[:10]}"
    now = datetime.utcnow().isoformat()
    requested_role = body.role
    assigned_role = "student"

    with get_conn() as conn:
        existing = conn.execute(
            "SELECT id FROM users WHERE email = ? OR matric_number = ?",
            (body.email.lower(), body.matric_number),
        ).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="Email or matric already exists")

        conn.execute(
            """
            INSERT INTO users
            (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                body.full_name,
                body.email.lower(),
                hash_password(body.password),
                body.matric_number,
                body.department,
                body.phone_number,
                assigned_role,
                now,
            ),
        )

        if body.selected_course_ids and requested_role in {"student", "course_rep"}:
            for course_id in dict.fromkeys(body.selected_course_ids):
                course = conn.execute(
                    "SELECT id FROM courses WHERE id = ?",
                    (course_id,),
                ).fetchone()
                if course:
                    _enroll_user_in_course(conn, user_id, course_id)

        role_application = None
        if requested_role in {"course_rep", "lecturer", "admin"}:
            app_id = f"ra_{uuid.uuid4().hex[:10]}"
            conn.execute(
                """
                INSERT INTO role_applications
                (id, user_id, requested_role, status, justification, created_at)
                VALUES (?, ?, ?, 'pending', ?, ?)
                """,
                (app_id, user_id, requested_role, body.role_justification, now),
            )
            role_application = {
                "id": app_id,
                "requested_role": requested_role,
                "status": "pending",
            }

        conn.commit()

    with get_conn() as conn:
        user_row = conn.execute(
            "SELECT id, full_name, email, matric_number, department, phone_number, role, created_at, is_active, blocked_at, blocked_reason FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()

    token = create_access_token(user_id=user_id, role=assigned_role)
    return {
        "access_token": token,
        "user": _user_payload(user_row),
        "requested_role": requested_role,
        "role_application": role_application,
        "message": (
            "Role application submitted and pending super admin approval."
            if role_application
            else "Registered successfully as student."
        ),
    }


@app.post("/auth/login")
def login(body: LoginRequest) -> dict:
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at, is_active, blocked_at, blocked_reason FROM users WHERE email = ?",
            (body.email.lower(),),
        ).fetchone()

    if not row or not verify_password(body.password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if int(row["is_active"] or 0) != 1:
        raise HTTPException(status_code=403, detail="This account is blocked")

    token = create_access_token(user_id=row["id"], role=row["role"])
    return {"access_token": token, "user": _user_payload(row)}


@app.get("/auth/me")
def me(user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        row = conn.execute(
            "SELECT id, full_name, email, matric_number, department, phone_number, role, created_at, is_active, blocked_at, blocked_reason FROM users WHERE id = ?",
            (user["user_id"],),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user": _user_payload(row)}


@app.get("/auth/role-applications/me")
def my_role_applications(user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT id, requested_role, status, justification, reviewed_by, reviewed_at, created_at
            FROM role_applications
            WHERE user_id = ?
            ORDER BY created_at DESC
            """,
            (user["user_id"],),
        ).fetchall()
    return {"applications": [dict(r) for r in rows]}


@app.get("/courses")
def list_courses(user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        if user["role"] in {"admin", "super_admin"}:
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
            ).fetchall()
        elif user["role"] == "lecturer":
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                WHERE c.lecturer_id = ?
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                (user["user_id"],),
            ).fetchall()
        elif user["role"] == "course_rep":
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                                LEFT JOIN course_enrollments self_enroll
                                    ON self_enroll.course_id = c.id AND self_enroll.student_id = ?
                                WHERE c.course_rep_id = ? OR self_enroll.id IS NOT NULL
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                                (user["user_id"], user["user_id"]),
            ).fetchall()
        else:
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                WHERE e.student_id = ?
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                (user["user_id"],),
            ).fetchall()

        courses = [_course_payload_from_row(row, _can_manage_course(conn, user, row["id"])) for row in rows]

    return {"courses": courses}


@app.get("/admin/users")
def list_users(role: str | None = None, user=Depends(_require_user)) -> dict:
    _ensure_super_admin(user)
    with get_conn() as conn:
        rows = _get_admin_user_rows(conn, role=role)
    return {"users": [_admin_user_payload(row) for row in rows]}


@app.put("/admin/users/{target_user_id}")
def update_user(target_user_id: str, body: AdminUserUpdateRequest, user=Depends(_require_user)) -> dict:
    _ensure_super_admin(user)
    if target_user_id == user["user_id"]:
        raise HTTPException(status_code=400, detail="You cannot modify your own account here")
    _ensure_manageable_user_role(body.role)

    with get_conn() as conn:
        existing = conn.execute("SELECT * FROM users WHERE id = ?", (target_user_id,)).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        if existing["role"] == "super_admin":
            raise HTTPException(status_code=403, detail="Super admin accounts cannot be modified here")

        email = body.email.lower()
        clash = conn.execute(
            "SELECT id FROM users WHERE (email = ? OR matric_number = ?) AND id != ?",
            (email, body.matric_number, target_user_id),
        ).fetchone()
        if clash:
            raise HTTPException(status_code=409, detail="Email or matric number already exists")

        conn.execute(
            """
            UPDATE users
            SET full_name = ?, email = ?, matric_number = ?, department = ?, phone_number = ?, role = ?
            WHERE id = ?
            """,
            (
                body.full_name.strip(),
                email,
                body.matric_number.strip(),
                body.department.strip(),
                body.phone_number.strip() if body.phone_number else None,
                body.role,
                target_user_id,
            ),
        )

        if body.role == "lecturer":
            conn.execute(
                "UPDATE courses SET lecturer_display_name = ? WHERE lecturer_id = ?",
                (body.full_name.strip(), target_user_id),
            )

        conn.commit()
        row = conn.execute(
            "SELECT id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at, is_active, blocked_at, blocked_reason FROM users WHERE id = ?",
            (target_user_id,),
        ).fetchone()

    return {"user": _admin_user_payload(row)}


@app.post("/admin/users/{target_user_id}/block")
def block_user(target_user_id: str, body: AdminUserBlockRequest, user=Depends(_require_user)) -> dict:
    _ensure_super_admin(user)
    if target_user_id == user["user_id"]:
        raise HTTPException(status_code=400, detail="You cannot block your own account")

    now = datetime.utcnow().isoformat()
    with get_conn() as conn:
        existing = conn.execute("SELECT id, role FROM users WHERE id = ?", (target_user_id,)).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        if existing["role"] == "super_admin":
            raise HTTPException(status_code=403, detail="Super admin accounts cannot be blocked here")

        conn.execute(
            "UPDATE users SET is_active = 0, blocked_at = ?, blocked_reason = ? WHERE id = ?",
            (now, body.reason, target_user_id),
        )
        conn.commit()

    return {"ok": True, "blocked": True}


@app.post("/admin/users/{target_user_id}/unblock")
def unblock_user(target_user_id: str, user=Depends(_require_user)) -> dict:
    _ensure_super_admin(user)
    with get_conn() as conn:
        existing = conn.execute("SELECT id, role FROM users WHERE id = ?", (target_user_id,)).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        if existing["role"] == "super_admin":
            raise HTTPException(status_code=403, detail="Super admin accounts cannot be unblocked here")

        conn.execute(
            "UPDATE users SET is_active = 1, blocked_at = NULL, blocked_reason = NULL WHERE id = ?",
            (target_user_id,),
        )
        conn.commit()

    return {"ok": True, "blocked": False}


@app.delete("/admin/users/{target_user_id}")
def delete_user(target_user_id: str, user=Depends(_require_user)) -> dict:
    _ensure_super_admin(user)
    if target_user_id == user["user_id"]:
        raise HTTPException(status_code=400, detail="You cannot delete your own account")

    with get_conn() as conn:
        existing = conn.execute("SELECT id, role FROM users WHERE id = ?", (target_user_id,)).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        if existing["role"] == "super_admin":
            raise HTTPException(status_code=403, detail="Super admin accounts cannot be deleted here")

        _delete_user_with_dependents(conn, target_user_id)
        conn.commit()

    return {"ok": True}


@app.get("/sessions/{session_id}/qr")
def session_qr(session_id: str, phase: str = "checkin", user=Depends(_require_user)) -> dict:
    if phase not in {"checkin", "checkout"}:
        raise HTTPException(status_code=400, detail="Invalid QR phase")

    with get_conn() as conn:
        session = _ensure_can_manage_session(conn, user, session_id)
        course_id = session["course_id"]
        if phase == "checkin" and session["status"] not in {"pending", "open_for_check_in"}:
            raise HTTPException(status_code=409, detail="Check-in QR can only be generated for an open check-in session")
        if phase == "checkout" and session["status"] != "open_for_check_out":
            raise HTTPException(status_code=409, detail="Check-out QR can only be generated after check-out is opened")

        payload = _build_qr_payload(session_id, course_id, phase)

    return {
        "session_id": session_id,
        "course_id": course_id,
        "phase": phase,
        "payload": payload,
        "expires_in_seconds": QR_ROTATION_SECONDS,
        "expires_at": datetime.utcnow().isoformat(),
    }


@app.get("/analytics/course/{course_id}")
def course_analytics(course_id: str, user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        _ensure_course_access(conn, user, course_id)

        course = conn.execute(
            """
            SELECT c.id, c.course_code, c.course_name, c.semester, c.academic_year,
                   COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name,
                   c.lecturer_id, c.course_rep_id, COUNT(DISTINCT e.id) AS enrolled_count
            FROM courses c
            INNER JOIN users l ON l.id = c.lecturer_id
            LEFT JOIN course_enrollments e ON e.course_id = c.id
            WHERE c.id = ?
            GROUP BY c.id
            """,
            (course_id,),
        ).fetchone()
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        sessions = conn.execute(
            """
            SELECT id, status, scheduled_date, class_type, classroom_latitude, classroom_longitude
            FROM attendance_sessions
            WHERE course_id = ?
            ORDER BY scheduled_date DESC
            """,
            (course_id,),
        ).fetchall()
        session_count = len(sessions)
        can_manage = _can_manage_course(conn, user, course_id)

        student_rows = conn.execute(
            """
            SELECT u.id, u.full_name, u.email, u.matric_number, u.department, u.phone_number,
                   COUNT(DISTINCT a.session_id) AS attended_count,
                   SUM(CASE WHEN a.check_in_time IS NOT NULL THEN 1 ELSE 0 END) AS check_in_count,
                   SUM(CASE WHEN a.check_out_time IS NOT NULL THEN 1 ELSE 0 END) AS check_out_count,
                   SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) AS present_count,
                   SUM(CASE WHEN a.status = 'partial' THEN 1 ELSE 0 END) AS partial_count
            FROM course_enrollments e
            INNER JOIN users u ON u.id = e.student_id
            LEFT JOIN attendance_records a ON a.student_id = u.id
            LEFT JOIN attendance_sessions s ON s.id = a.session_id AND s.course_id = e.course_id
            WHERE e.course_id = ?
            GROUP BY u.id
            ORDER BY u.full_name ASC
            """,
            (course_id,),
        ).fetchall()

        total_present = 0
        total_partial = 0
        students = []
        for row in student_rows:
            present_count = int(row["present_count"] or 0)
            partial_count = int(row["partial_count"] or 0)
            check_in_count = int(row["check_in_count"] or 0)
            check_out_count = int(row["check_out_count"] or 0)
            attended_count = int(row["attended_count"] or 0)
            attendance_rate = round((present_count / session_count) * 100, 1) if session_count else 0.0
            total_present += present_count
            total_partial += partial_count
            students.append(
                {
                    "id": row["id"],
                    "fullName": row["full_name"],
                    "email": row["email"],
                    "matricNumber": row["matric_number"],
                    "department": row["department"],
                    "phoneNumber": row["phone_number"],
                    "attendedCount": attended_count,
                    "presentCount": present_count,
                    "partialCount": partial_count,
                    "checkInCount": check_in_count,
                    "checkOutCount": check_out_count,
                    "sessionCount": session_count,
                    "attendanceRate": attendance_rate,
                }
            )

    return {
        "course": {
            "id": course["id"],
            "courseCode": course["course_code"],
            "courseName": course["course_name"],
            "lecturerName": course["lecturer_name"],
            "semester": course["semester"],
            "academicYear": course["academic_year"],
            "enrolledCount": int(course["enrolled_count"] or 0),
            "sessionCount": session_count,
            "presentCount": total_present,
            "partialCount": total_partial,
            "canManage": can_manage,
        },
        "sessions": [dict(row) for row in sessions],
        "students": students,
    }


@app.get("/courses/catalog")
def public_course_catalog() -> dict:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
            FROM courses c
            INNER JOIN users l ON l.id = c.lecturer_id
            LEFT JOIN course_enrollments e ON e.course_id = c.id
            GROUP BY c.id
            ORDER BY c.course_code ASC
            """
        ).fetchall()
    return {"courses": [dict(r) for r in rows]}


@app.get("/courses/available")
def public_course_catalog_available() -> dict:
    # Compatibility alias used by some older clients.
    return public_course_catalog()


@app.get("/course-catalog")
def public_course_catalog_legacy() -> dict:
    # Legacy compatibility alias.
    return public_course_catalog()


@app.post("/courses")
def create_course(body: CourseCreateRequest, user=Depends(_require_user)) -> dict:
    if user["role"] not in {"lecturer", "admin", "super_admin"}:
        raise HTTPException(status_code=403, detail="Only lecturers, admins, and super admins can create courses")

    with get_conn() as conn:
        lecturer_id = body.lecturer_id
        lecturer_display_name = None
        if user["role"] == "lecturer":
            lecturer_id = user["user_id"]
            lecturer_display_name = _get_user_full_name(conn, user["user_id"])
        elif not lecturer_id and body.lecturer_identifier:
            lecturer_id = _resolve_lecturer_identifier(conn, body.lecturer_identifier)
            lecturer_display_name = body.lecturer_identifier.strip()

        if not lecturer_id and not lecturer_display_name:
            raise HTTPException(status_code=400, detail="lecturer_id or lecturer_identifier is required for this role")

        if lecturer_id:
            lecturer = conn.execute(
                "SELECT id, role, full_name FROM users WHERE id = ?",
                (lecturer_id,),
            ).fetchone()
            if not lecturer:
                raise HTTPException(status_code=400, detail="Assigned lecturer does not exist")
            if lecturer["role"] != "lecturer":
                raise HTTPException(status_code=400, detail="Assigned lecturer does not exist or is not a lecturer")
            lecturer_display_name = lecturer["full_name"]
        else:
            if user["role"] == "lecturer":
                lecturer_id = user["user_id"]
                lecturer_display_name = _get_user_full_name(conn, user["user_id"])
            else:
                raise HTTPException(status_code=400, detail="lecturer_id or lecturer_identifier is required for this role")

        if body.course_rep_id:
            rep = conn.execute(
                "SELECT id, role FROM users WHERE id = ?",
                (body.course_rep_id,),
            ).fetchone()
            if not rep or rep["role"] != "course_rep":
                raise HTTPException(status_code=400, detail="Assigned course rep does not exist or is not a course rep")

        normalized_code = body.course_code.strip().upper()
        existing = conn.execute(
            "SELECT id FROM courses WHERE upper(course_code) = ?",
            (normalized_code,),
        ).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="Course code already exists")

        course_id = f"c_{uuid.uuid4().hex[:10]}"
        conn.execute(
            """
            INSERT INTO courses
            (id, course_code, course_name, lecturer_id, lecturer_display_name, course_rep_id, semester, academic_year)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                course_id,
                normalized_code,
                body.course_name.strip(),
                lecturer_id,
                lecturer_display_name,
                body.course_rep_id,
                body.semester.strip(),
                body.academic_year,
            ),
        )

        conn.commit()

        row = conn.execute(
            """
            SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, 0 AS enrolled_count
            FROM courses c
            INNER JOIN users l ON l.id = c.lecturer_id
            WHERE c.id = ?
            """,
            (course_id,),
        ).fetchone()
        can_manage = _can_manage_course(conn, user, course_id)

    course = dict(row)
    course["can_manage"] = can_manage
    return {"course": course}


@app.get("/me/courses")
def my_courses(user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        if user["role"] in {"admin", "super_admin"}:
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
            ).fetchall()
        elif user["role"] == "lecturer":
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                WHERE c.lecturer_id = ?
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                (user["user_id"],),
            ).fetchall()
        elif user["role"] == "course_rep":
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                WHERE c.course_rep_id = ?
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                (user["user_id"],),
            ).fetchall()
        else:
            rows = conn.execute(
                """
                SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                WHERE e.student_id = ?
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                (user["user_id"],),
            ).fetchall()

        courses = [_course_payload_from_row(row, _can_manage_course(conn, user, row["id"])) for row in rows]

    return {"courses": courses}


@app.post("/me/courses/{course_id}")
def enroll_me_in_course(course_id: str, user=Depends(_require_user)) -> dict:
    if user["role"] not in {"student", "course_rep"}:
        raise HTTPException(status_code=403, detail="Only students and course reps can enroll in courses")

    with get_conn() as conn:
        course = conn.execute(
            "SELECT id FROM courses WHERE id = ?",
            (course_id,),
        ).fetchone()
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        _enroll_user_in_course(conn, user["user_id"], course_id)
        conn.commit()

        row = conn.execute(
            """
            SELECT c.*, COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(e.id) AS enrolled_count
            FROM courses c
            INNER JOIN users l ON l.id = c.lecturer_id
            LEFT JOIN course_enrollments e ON e.course_id = c.id
            WHERE c.id = ?
            GROUP BY c.id
            """,
            (course_id,),
        ).fetchone()
        can_manage = _can_manage_course(conn, user, course_id)
    return {"course": _course_payload_from_row(row, can_manage)}


@app.delete("/me/courses/{course_id}")
def unenroll_me_from_course(course_id: str, user=Depends(_require_user)) -> dict:
    if user["role"] not in {"student", "course_rep"}:
        raise HTTPException(status_code=403, detail="Only students and course reps can remove courses")

    with get_conn() as conn:
        course = conn.execute(
            "SELECT id FROM courses WHERE id = ?",
            (course_id,),
        ).fetchone()
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        _unenroll_user_from_course(conn, user["user_id"], course_id)
        conn.commit()

    return {"ok": True}


@app.get("/analytics/dashboard")
def dashboard_analytics(user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        if user["role"] in {"admin", "super_admin"}:
            visible_rows = conn.execute(
                """
                SELECT c.id, c.course_code, c.course_name, c.lecturer_id, c.course_rep_id,
                       COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(DISTINCT e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
            ).fetchall()
        elif user["role"] == "lecturer":
            visible_rows = conn.execute(
                """
                SELECT c.id, c.course_code, c.course_name, c.lecturer_id, c.course_rep_id,
                       COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(DISTINCT e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                WHERE c.lecturer_id = ?
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                (user["user_id"],),
            ).fetchall()
        else:
            visible_rows = conn.execute(
                """
                SELECT c.id, c.course_code, c.course_name, c.lecturer_id, c.course_rep_id,
                       COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name, COUNT(DISTINCT e.id) AS enrolled_count
                FROM courses c
                INNER JOIN users l ON l.id = c.lecturer_id
                INNER JOIN course_enrollments me ON me.course_id = c.id AND me.student_id = ?
                LEFT JOIN course_enrollments e ON e.course_id = c.id
                GROUP BY c.id
                ORDER BY c.course_code ASC
                """,
                (user["user_id"],),
            ).fetchall()

        course_ids = [row["id"] for row in visible_rows]
        session_lookup = {}
        attendance_lookup = {}
        if course_ids:
            placeholders = ",".join("?" for _ in course_ids)
            session_rows = conn.execute(
                f"""
                SELECT course_id,
                       COUNT(*) AS session_count,
                       SUM(CASE WHEN status IN ('open_for_check_in', 'open_for_check_out') THEN 1 ELSE 0 END) AS active_session_count
                FROM attendance_sessions
                WHERE course_id IN ({placeholders})
                GROUP BY course_id
                """,
                course_ids,
            ).fetchall()
            attendance_rows = conn.execute(
                f"""
                SELECT s.course_id,
                       COUNT(a.id) AS record_count,
                       SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) AS present_count,
                       SUM(CASE WHEN a.status = 'partial' THEN 1 ELSE 0 END) AS partial_count,
                       SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END) AS absent_count
                FROM attendance_sessions s
                LEFT JOIN attendance_records a ON a.session_id = s.id
                WHERE s.course_id IN ({placeholders})
                GROUP BY s.course_id
                """,
                course_ids,
            ).fetchall()

            session_lookup = {row["course_id"]: dict(row) for row in session_rows}
            attendance_lookup = {row["course_id"]: dict(row) for row in attendance_rows}

        course_summaries = []
        total_sessions = 0
        total_present = 0
        total_partial = 0
        total_absent = 0
        active_sessions = 0

        for row in visible_rows:
            attendance = attendance_lookup.get(row["id"], {})
            sessions = session_lookup.get(row["id"], {})
            session_count = int(sessions.get("session_count") or 0)
            active_session_count = int(sessions.get("active_session_count") or 0)
            present_count = int(attendance.get("present_count") or 0)
            partial_count = int(attendance.get("partial_count") or 0)
            absent_count = int(attendance.get("absent_count") or 0)
            enrolled_count = int(row["enrolled_count"] or 0)
            completed = present_count + partial_count + absent_count
            attendance_rate = round((present_count / enrolled_count) * 100, 1) if enrolled_count else 0.0

            total_sessions += session_count
            total_present += present_count
            total_partial += partial_count
            total_absent += absent_count
            active_sessions += active_session_count

            course_summaries.append(
                {
                    "id": row["id"],
                    "courseCode": row["course_code"],
                    "courseName": row["course_name"],
                    "lecturerName": row["lecturer_name"],
                    "enrolledCount": enrolled_count,
                    "sessionCount": session_count,
                    "activeSessionCount": active_session_count,
                    "presentCount": present_count,
                    "partialCount": partial_count,
                    "absentCount": absent_count,
                    "recordCount": completed,
                    "attendanceRate": attendance_rate,
                    "canManage": _can_manage_course(conn, user, row["id"]),
                }
            )

        total_enrolled = len(visible_rows) if user["role"] == "student" or user["role"] == "course_rep" else sum(
            int(row["enrolled_count"] or 0) for row in visible_rows
        )

    return {
        "role": user["role"],
        "summary": {
            "visibleCourseCount": len(visible_rows),
            "totalEnrolledCount": total_enrolled,
            "totalSessionCount": total_sessions,
            "activeSessionCount": active_sessions,
            "presentCount": total_present,
            "partialCount": total_partial,
            "absentCount": total_absent,
        },
        "courses": course_summaries,
    }


@app.post("/sessions")
def create_session(body: SessionCreateRequest, user=Depends(_require_user)) -> dict:
    if user["role"] not in {"lecturer", "course_rep", "admin", "super_admin"}:
        raise HTTPException(status_code=403, detail="Only staff can create sessions")

    session_id = f"sess_{uuid.uuid4().hex[:10]}"
    now = datetime.utcnow().isoformat()

    with get_conn() as conn:
        course = conn.execute(
            "SELECT id FROM courses WHERE id = ?",
            (body.course_id,),
        ).fetchone()
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        _ensure_can_manage_course(conn, user, body.course_id)

        existing_active = conn.execute(
            """
            SELECT id FROM attendance_sessions
            WHERE course_id = ?
              AND status IN ('open_for_check_in', 'open_for_check_out')
            ORDER BY scheduled_date DESC
            LIMIT 1
            """,
            (body.course_id,),
        ).fetchone()
        if existing_active:
            raise HTTPException(
                status_code=409,
                detail="An active attendance session already exists for this course",
            )

        conn.execute(
            """
            INSERT INTO attendance_sessions
            (id, course_id, class_type, scheduled_date, status, check_in_opened_at, classroom_latitude,
             classroom_longitude, created_by, created_at)
            VALUES (?, ?, ?, ?, 'open_for_check_in', ?, ?, ?, ?, ?)
            """,
            (
                session_id,
                body.course_id,
                body.class_type,
                body.scheduled_date,
                now,
                body.classroom_latitude,
                body.classroom_longitude,
                user["user_id"],
                now,
            ),
        )
        conn.commit()

    with get_conn() as conn:
        row = conn.execute(
            "SELECT * FROM attendance_sessions WHERE id = ?",
            (session_id,),
        ).fetchone()
    return {"session": dict(row)}


@app.get("/sessions/course/{course_id}")
def sessions_for_course(course_id: str, user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        _ensure_course_access(conn, user, course_id)
        rows = conn.execute(
            "SELECT * FROM attendance_sessions WHERE course_id = ? ORDER BY scheduled_date DESC",
            (course_id,),
        ).fetchall()
    return {"sessions": [dict(r) for r in rows]}


@app.get("/sessions/{session_id}")
def session_detail(session_id: str, user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        _ensure_session_access(conn, user, session_id)
        row = conn.execute(
            """
             SELECT s.*, c.course_code, c.course_name,
                 COALESCE(c.lecturer_display_name, l.full_name) AS lecturer_name,
                   rep.full_name AS course_rep_name,
                   rep.email AS course_rep_email
            FROM attendance_sessions s
            INNER JOIN courses c ON c.id = s.course_id
            INNER JOIN users l ON l.id = c.lecturer_id
            LEFT JOIN users rep ON rep.id = c.course_rep_id
            WHERE s.id = ?
            """,
            (session_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"session": dict(row)}


@app.get("/sessions/active/{course_id}")
def active_session(course_id: str, user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        _ensure_course_access(conn, user, course_id)
        row = conn.execute(
            """
            SELECT * FROM attendance_sessions
            WHERE course_id = ?
              AND status IN ('open_for_check_in', 'open_for_check_out')
            ORDER BY scheduled_date DESC
            LIMIT 1
            """,
            (course_id,),
        ).fetchone()
    return {"session": dict(row) if row else None}


@app.put("/sessions/{session_id}")
def update_session(session_id: str, body: SessionCreateRequest, user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        _ensure_can_manage_session(conn, user, session_id)
        _ensure_can_manage_course(conn, user, body.course_id)
        conn.execute(
            """
            UPDATE attendance_sessions
            SET course_id = ?,
                class_type = ?,
                scheduled_date = ?,
                classroom_latitude = ?,
                classroom_longitude = ?
            WHERE id = ?
            """,
            (
                body.course_id,
                body.class_type,
                body.scheduled_date,
                body.classroom_latitude,
                body.classroom_longitude,
                session_id,
            ),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM attendance_sessions WHERE id = ?",
            (session_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"session": dict(row)}


@app.post("/sessions/{session_id}/open-checkout")
def open_checkout(session_id: str, user=Depends(_require_user)) -> dict:
    now = datetime.utcnow().isoformat()
    with get_conn() as conn:
        session = _ensure_can_manage_session(conn, user, session_id)
        if session["status"] == "closed":
            raise HTTPException(status_code=409, detail="Cannot reopen a closed session")
        if session["status"] == "open_for_check_out":
            row = conn.execute(
                "SELECT * FROM attendance_sessions WHERE id = ?",
                (session_id,),
            ).fetchone()
            return {"session": dict(row)}
        _ensure_checkout_window_openable(session)

        conn.execute(
            """
            UPDATE attendance_sessions
            SET status = 'open_for_check_out',
                check_out_opened_at = ?
            WHERE id = ?
            """,
            (now, session_id),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM attendance_sessions WHERE id = ?",
            (session_id,),
        ).fetchone()
    return {"session": dict(row)}


@app.post("/sessions/{session_id}/close")
def close_session(session_id: str, user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        _ensure_can_manage_session(conn, user, session_id)
        conn.execute(
            """
            UPDATE attendance_sessions
            SET status = 'closed'
            WHERE id = ?
            """,
            (session_id,),
        )
        conn.commit()
        row = conn.execute(
            "SELECT * FROM attendance_sessions WHERE id = ?",
            (session_id,),
        ).fetchone()
    return {"session": dict(row)}


@app.post("/attendance/checkin")
def check_in(body: CheckRequest, user=Depends(_require_user)) -> dict:
    now = datetime.utcnow().isoformat()

    if body.student_id != user["user_id"]:
        raise HTTPException(status_code=403, detail="You can only mark attendance for your own account")

    with get_conn() as conn:
        session = conn.execute(
            "SELECT id, course_id, status, classroom_latitude, classroom_longitude FROM attendance_sessions WHERE id = ?",
            (body.session_id,),
        ).fetchone()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        _ensure_course_access(conn, user, session["course_id"])

        if session["status"] != "open_for_check_in":
            raise HTTPException(status_code=400, detail="Session not open for check-in")

        if body.qr_payload:
            _validate_qr_payload(
                body.qr_payload,
                expected_session_id=body.session_id,
                expected_course_id=session["course_id"],
                expected_phase="checkin",
            )

        existing = conn.execute(
            "SELECT id, check_in_time FROM attendance_records WHERE session_id = ? AND student_id = ?",
            (body.session_id, body.student_id),
        ).fetchone()
        if existing and existing["check_in_time"]:
            raise HTTPException(status_code=409, detail="Already checked in")

        _ensure_session_within_radius(session, body.latitude, body.longitude)
        _ensure_device_bound_to_student(conn, body.student_id, body.device_id)
        _ensure_device_not_used_by_other_student(conn, body.session_id, body.student_id, body.device_id)

        conn.execute(
            """
            INSERT INTO attendance_records
            (id, session_id, student_id, check_in_time, check_in_latitude, check_in_longitude,
             device_id, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'partial', ?, ?)
            ON CONFLICT(session_id, student_id)
            DO UPDATE SET
              check_in_time = excluded.check_in_time,
              check_in_latitude = excluded.check_in_latitude,
              check_in_longitude = excluded.check_in_longitude,
              device_id = excluded.device_id,
              status = 'partial',
              updated_at = excluded.updated_at
            """,
            (
                f"rec_{uuid.uuid4().hex[:10]}",
                body.session_id,
                body.student_id,
                now,
                body.latitude,
                body.longitude,
                body.device_id,
                now,
                now,
            ),
        )
        conn.commit()

    return {"ok": True, "status": "partial", "checked_at": now}


@app.post("/attendance/checkout")
def check_out(body: CheckRequest, user=Depends(_require_user)) -> dict:
    now = datetime.utcnow().isoformat()

    if body.student_id != user["user_id"]:
        raise HTTPException(status_code=403, detail="You can only mark attendance for your own account")

    with get_conn() as conn:
        session = conn.execute(
            "SELECT id, course_id, status, classroom_latitude, classroom_longitude FROM attendance_sessions WHERE id = ?",
            (body.session_id,),
        ).fetchone()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        _ensure_course_access(conn, user, session["course_id"])

        if session["status"] not in {"open_for_check_in", "open_for_check_out"}:
            raise HTTPException(status_code=400, detail="Session not open for check-out")

        if body.qr_payload:
            _validate_qr_payload(
                body.qr_payload,
                expected_session_id=body.session_id,
                expected_course_id=session["course_id"],
                expected_phase="checkout",
            )

        record = conn.execute(
            "SELECT id, check_in_time, check_out_time FROM attendance_records WHERE session_id = ? AND student_id = ?",
            (body.session_id, body.student_id),
        ).fetchone()
        if not record or not record["check_in_time"]:
            raise HTTPException(status_code=400, detail="Check-in required before check-out")

        _ensure_session_within_radius(session, body.latitude, body.longitude)
        _ensure_device_bound_to_student(conn, body.student_id, body.device_id)
        _ensure_device_not_used_by_other_student(conn, body.session_id, body.student_id, body.device_id)
        if record["check_out_time"]:
            raise HTTPException(status_code=409, detail="Already checked out")

        conn.execute(
            """
            UPDATE attendance_records
            SET check_out_time = ?,
                check_out_latitude = ?,
                check_out_longitude = ?,
                status = 'present',
                updated_at = ?
            WHERE session_id = ? AND student_id = ?
            """,
            (now, body.latitude, body.longitude, now, body.session_id, body.student_id),
        )
        conn.commit()

    return {"ok": True, "status": "present", "checked_at": now}


@app.post("/attendance/manual-add")
def manual_add_attendance(body: ManualAttendanceRequest, user=Depends(_require_user)) -> dict:
    if user["role"] not in {"admin", "super_admin"}:
        raise HTTPException(status_code=403, detail="Only admin or super admin can manually override attendance")
    now = datetime.utcnow().isoformat()

    with get_conn() as conn:
        _ensure_session_access(conn, user, body.session_id)
        session = conn.execute(
            "SELECT id FROM attendance_sessions WHERE id = ?",
            (body.session_id,),
        ).fetchone()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

        student = conn.execute(
            """
            SELECT id, full_name, matric_number, department
            FROM users
            WHERE lower(email) = lower(?) OR upper(matric_number) = upper(?)
            """,
            (body.student_identifier, body.student_identifier),
        ).fetchone()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")

        existing = conn.execute(
            "SELECT id FROM attendance_records WHERE session_id = ? AND student_id = ?",
            (body.session_id, student["id"]),
        ).fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="This student already has an attendance record for this session")

        record_id = f"rec_{uuid.uuid4().hex[:10]}"
        conn.execute(
            """
            INSERT INTO attendance_records
            (id, session_id, student_id, check_in_time, check_out_time, check_in_latitude, check_in_longitude,
             check_out_latitude, check_out_longitude, device_id, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                record_id,
                body.session_id,
                student["id"],
                now,
                now,
                None,
                None,
                None,
                None,
                None,
                "present",
                now,
                now,
            ),
        )
        conn.execute(
            """
            INSERT INTO attendance_manual_actions
            (id, session_id, student_id, added_by, reason, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                f"act_{uuid.uuid4().hex[:10]}",
                body.session_id,
                student["id"],
                user["user_id"],
                body.reason,
                now,
            ),
        )
        conn.commit()

    return {
        "ok": True,
        "record": {
            "id": record_id,
            "session_id": body.session_id,
            "student_id": student["id"],
            "student_name": student["full_name"],
            "matric_number": student["matric_number"],
            "department": student["department"],
            "status": "manual",
            "manual_added_by": user["user_id"],
            "manual_added_at": now,
            "reason": body.reason,
        },
    }


@app.post("/attendance/anomalies")
def flag_attendance_anomaly(body: AttendanceAnomalyRequest, user=Depends(_require_user)) -> dict:
    if user["role"] not in {"course_rep", "lecturer", "admin", "super_admin"}:
        raise HTTPException(status_code=403, detail="Only staff can flag attendance anomalies")

    now = datetime.utcnow().isoformat()
    with get_conn() as conn:
        session = _ensure_session_access(conn, user, body.session_id)

        student = conn.execute(
            "SELECT id, role FROM users WHERE id = ?",
            (body.student_id,),
        ).fetchone()
        if not student or student["role"] not in {"student", "course_rep"}:
            raise HTTPException(status_code=404, detail="Target student not found")

        _ensure_course_access(conn, user, session["course_id"])
        anomaly_id = f"an_{uuid.uuid4().hex[:10]}"
        conn.execute(
            """
            INSERT INTO attendance_anomalies
            (id, session_id, student_id, flagged_by, reason, details, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                anomaly_id,
                body.session_id,
                body.student_id,
                user["user_id"],
                body.reason.strip(),
                body.details.strip() if body.details else None,
                now,
            ),
        )
        conn.commit()

    return {"ok": True, "anomaly_id": anomaly_id}


@app.get("/attendance/session/{session_id}")
def session_attendance(session_id: str, user=Depends(_require_user)) -> dict:
    if user["role"] not in {"lecturer", "course_rep", "admin", "super_admin"}:
        raise HTTPException(status_code=403, detail="Only staff can view full session attendance")

    with get_conn() as conn:
        _ensure_session_access(conn, user, session_id)
        rows = conn.execute(
            """
            SELECT a.*, u.full_name, u.matric_number, u.department, u.phone_number
            FROM attendance_records a
            INNER JOIN users u ON u.id = a.student_id
            WHERE a.session_id = ?
            ORDER BY u.full_name ASC
            """,
            (session_id,),
        ).fetchall()

        manual_rows = conn.execute(
            """
            SELECT m.session_id, m.student_id, m.added_by, m.reason, m.created_at,
                   u.full_name AS added_by_name
            FROM attendance_manual_actions m
            INNER JOIN users u ON u.id = m.added_by
            WHERE m.session_id = ?
            """,
            (session_id,),
        ).fetchall()

        anomaly_rows = conn.execute(
            """
            SELECT a.session_id, a.student_id, a.flagged_by, a.reason, a.details, a.created_at,
                   u.full_name AS flagged_by_name
            FROM attendance_anomalies a
            INNER JOIN users u ON u.id = a.flagged_by
            WHERE a.session_id = ?
            ORDER BY a.created_at DESC
            """,
            (session_id,),
        ).fetchall()

    manual_lookup = {
        (r["session_id"], r["student_id"]): dict(r) for r in manual_rows
    }
    anomaly_lookup = {}
    for row in anomaly_rows:
        key = (row["session_id"], row["student_id"])
        anomaly_lookup.setdefault(key, []).append(dict(row))

    records = []
    for row in rows:
        record = dict(row)
        manual = manual_lookup.get((session_id, record["student_id"]))
        record["manual_added"] = manual is not None
        record["manual_added_by"] = manual["added_by"] if manual else None
        record["manual_added_by_name"] = manual["added_by_name"] if manual else None
        record["manual_added_at"] = manual["created_at"] if manual else None
        record["manual_reason"] = manual["reason"] if manual else None
        record["anomalies"] = anomaly_lookup.get((session_id, record["student_id"]), [])
        records.append(record)

    return {"records": records}


@app.get("/attendance/me")
def my_attendance(user=Depends(_require_user)) -> dict:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT a.*, s.scheduled_date, c.course_code, c.course_name
            FROM attendance_records a
            INNER JOIN attendance_sessions s ON s.id = a.session_id
            INNER JOIN courses c ON c.id = s.course_id
            WHERE a.student_id = ?
            ORDER BY s.scheduled_date DESC
            """,
            (user["user_id"],),
        ).fetchall()
    return {"records": [dict(r) for r in rows]}


@app.get("/admin/role-applications")
def list_role_applications(status: str = "pending", user=Depends(_require_user)) -> dict:
    _ensure_super_admin(user)
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT ra.*, u.full_name, u.email, u.matric_number, u.department, u.phone_number
            FROM role_applications ra
            INNER JOIN users u ON u.id = ra.user_id
            WHERE ra.status = ?
            ORDER BY ra.created_at ASC
            """,
            (status,),
        ).fetchall()
    return {"applications": [dict(r) for r in rows]}


@app.post("/admin/role-applications/{application_id}/approve")
def approve_role_application(
    application_id: str,
    body: RoleApplicationActionRequest,
    user=Depends(_require_user),
) -> dict:
    _ensure_super_admin(user)
    now = datetime.utcnow().isoformat()

    with get_conn() as conn:
        app_row = conn.execute(
            "SELECT id, user_id, requested_role, status FROM role_applications WHERE id = ?",
            (application_id,),
        ).fetchone()
        if not app_row:
            raise HTTPException(status_code=404, detail="Role application not found")
        if app_row["status"] != "pending":
            raise HTTPException(status_code=409, detail="Role application already processed")

        conn.execute(
            "UPDATE users SET role = ? WHERE id = ?",
            (app_row["requested_role"], app_row["user_id"]),
        )

        if app_row["requested_role"] == "lecturer":
            lecturer = conn.execute(
                "SELECT full_name FROM users WHERE id = ?",
                (app_row["user_id"],),
            ).fetchone()
            if lecturer and lecturer["full_name"]:
                candidate_rows = conn.execute(
                    "SELECT id, lecturer_display_name FROM courses"
                ).fetchall()
                matched_course_ids = [
                    row["id"]
                    for row in candidate_rows
                    if _names_compatible(row["lecturer_display_name"], lecturer["full_name"])
                ]

                for course_id in matched_course_ids:
                    conn.execute(
                        """
                        UPDATE courses
                        SET lecturer_id = ?, lecturer_display_name = ?
                        WHERE id = ?
                        """,
                        (app_row["user_id"], lecturer["full_name"], course_id),
                    )

        conn.execute(
            """
            UPDATE role_applications
            SET status = 'approved', reviewed_by = ?, reviewed_at = ?, justification = COALESCE(?, justification)
            WHERE id = ?
            """,
            (user["user_id"], now, body.reason, application_id),
        )
        conn.commit()

    return {"ok": True, "status": "approved", "application_id": application_id}


@app.post("/admin/role-applications/{application_id}/reject")
def reject_role_application(
    application_id: str,
    body: RoleApplicationActionRequest,
    user=Depends(_require_user),
) -> dict:
    _ensure_super_admin(user)
    now = datetime.utcnow().isoformat()

    with get_conn() as conn:
        app_row = conn.execute(
            "SELECT id, status FROM role_applications WHERE id = ?",
            (application_id,),
        ).fetchone()
        if not app_row:
            raise HTTPException(status_code=404, detail="Role application not found")
        if app_row["status"] != "pending":
            raise HTTPException(status_code=409, detail="Role application already processed")

        conn.execute(
            """
            UPDATE role_applications
            SET status = 'rejected', reviewed_by = ?, reviewed_at = ?, justification = COALESCE(?, justification)
            WHERE id = ?
            """,
            (user["user_id"], now, body.reason, application_id),
        )
        conn.commit()

    return {"ok": True, "status": "rejected", "application_id": application_id}

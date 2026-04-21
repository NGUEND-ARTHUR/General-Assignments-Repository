import os
import uuid
from datetime import datetime

DB_PATH = os.path.join('data', 'verify_close_session.db')
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
os.environ['UNIATTEND_DB_PATH'] = DB_PATH

from app.db import init_db, get_conn
from app.main import app
from app.security import create_access_token
from fastapi.testclient import TestClient

init_db()
now = datetime.utcnow().isoformat()
PASSWORD_HASH_PLACEHOLDER = 'pbkdf2_sha256$100000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='

users = [
    ('u_admin_t', 'Admin Tester', 'admin.test@ictuniversity.edu.cm', 'admin', 'ADM-T-001'),
    ('u_super_t', 'Super Tester', 'super.test@ictuniversity.edu.cm', 'super_admin', 'SUP-T-001'),
    ('u_lec1_t', 'Lecturer One', 'lect1.test@ictuniversity.edu.cm', 'lecturer', 'LEC-T-001'),
    ('u_lec2_t', 'Lecturer Two', 'lect2.test@ictuniversity.edu.cm', 'lecturer', 'LEC-T-002'),
    ('u_rep1_t', 'Rep One', 'rep1.test@ictuniversity.edu.cm', 'course_rep', 'REP-T-001'),
    ('u_rep2_t', 'Rep Two', 'rep2.test@ictuniversity.edu.cm', 'course_rep', 'REP-T-002'),
    ('u_stu_t', 'Student One', 'student.test@ictuniversity.edu.cm', 'student', 'STU-T-001'),
]

courses = [
    ('c_manage_1', 'SEN9001', 'Managed Course', 'u_lec1_t', 'Lecturer One', 'u_rep1_t'),
    ('c_other_1', 'SEN9002', 'Other Course', 'u_lec2_t', 'Lecturer Two', 'u_rep2_t'),
]

sessions = [
    ('sess_lec_ok', 'c_manage_1'),
    ('sess_rep_ok', 'c_manage_1'),
    ('sess_admin_ok', 'c_other_1'),
    ('sess_super_ok', 'c_other_1'),
    ('sess_student_no', 'c_manage_1'),
    ('sess_lec_no', 'c_manage_1'),
    ('sess_rep_no', 'c_manage_1'),
]

with get_conn() as conn:
    for uid, name, email, role, matric in users:
        conn.execute(
            '''
            INSERT INTO users (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            (uid, name, email, PASSWORD_HASH_PLACEHOLDER, matric, 'SEN', '+237600000000', role, now),
        )

    for cid, code, cname, lec_id, lec_name, rep_id in courses:
        conn.execute(
            '''
            INSERT INTO courses (id, course_code, course_name, lecturer_id, lecturer_display_name, course_rep_id, semester, academic_year)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            (cid, code, cname, lec_id, lec_name, rep_id, 'Semester 1', 2026),
        )

    conn.execute(
        '''
        INSERT INTO course_enrollments (id, course_id, student_id, created_at)
        VALUES (?, ?, ?, ?)
        ''',
        (f'en_{uuid.uuid4().hex[:10]}', 'c_manage_1', 'u_stu_t', now),
    )

    for sid, cid in sessions:
        conn.execute(
            '''
            INSERT INTO attendance_sessions
            (id, course_id, class_type, scheduled_date, status, check_in_opened_at, classroom_latitude, classroom_longitude, created_by, created_at)
            VALUES (?, ?, 'normal', ?, 'open_for_check_in', ?, 3.8667, 11.5167, ?, ?)
            ''',
            (sid, cid, now, now, 'u_admin_t', now),
        )

    conn.commit()

client = TestClient(app)


def headers(user_id, role):
    token = create_access_token(user_id=user_id, role=role)
    return {'Authorization': f'Bearer {token}'}


cases = [
    ('Lecturer owner can close', 'sess_lec_ok', 'u_lec1_t', 'lecturer', 200),
    ('Course rep assigned can close', 'sess_rep_ok', 'u_rep1_t', 'course_rep', 200),
    ('Admin can close', 'sess_admin_ok', 'u_admin_t', 'admin', 200),
    ('Super admin can close', 'sess_super_ok', 'u_super_t', 'super_admin', 200),
    ('Student cannot close', 'sess_student_no', 'u_stu_t', 'student', 403),
    ('Other lecturer cannot close', 'sess_lec_no', 'u_lec2_t', 'lecturer', 403),
    ('Other course rep cannot close', 'sess_rep_no', 'u_rep2_t', 'course_rep', 403),
]

failures = []
print('--- Close Session Role Matrix ---')
for label, sid, uid, role, expected in cases:
    resp = client.post(f'/sessions/{sid}/close', headers=headers(uid, role))
    status = resp.status_code
    ok = status == expected
    body = resp.json()
    if status == 200:
        print(f"{label}: got={status} expected={expected} -> {'PASS' if ok else 'FAIL'} status_after={body.get('session', {}).get('status')}")
        with get_conn() as conn:
            row = conn.execute('SELECT status FROM attendance_sessions WHERE id = ?', (sid,)).fetchone()
        if not row or row['status'] != 'closed':
            ok = False
            failures.append(f"{label}: session not persisted as closed")
    else:
        print(f"{label}: got={status} expected={expected} -> {'PASS' if ok else 'FAIL'} detail={body.get('detail')}")

    if not ok:
        failures.append(f"{label}: got {status}, expected {expected}")

print('RESULT:', 'PASS' if not failures else 'FAIL')
if failures:
    for item in failures:
        print(' -', item)
    raise SystemExit(1)

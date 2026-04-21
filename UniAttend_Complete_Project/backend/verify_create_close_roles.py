import os
from datetime import datetime

DB_PATH = os.path.join('data', 'verify_create_close_roles.db')
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
os.environ['UNIATTEND_DB_PATH'] = DB_PATH

from fastapi.testclient import TestClient
from app.db import init_db, get_conn
from app.main import app
from app.security import create_access_token

init_db()
now = datetime.utcnow().isoformat()
PASS_HASH = 'pbkdf2_sha256$100000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='

with get_conn() as conn:
    users = [
        ('u_admin', 'Admin User', 'admin.verify+1@ictuniversity.edu.cm', 'admin', 'ADM001'),
        ('u_super', 'Super User', 'super.verify+1@ictuniversity.edu.cm', 'super_admin', 'SUP001'),
        ('u_lec', 'Lecturer User', 'lec.verify+1@ictuniversity.edu.cm', 'lecturer', 'LEC001'),
        ('u_rep', 'Rep User', 'rep.verify+1@ictuniversity.edu.cm', 'course_rep', 'REP001'),
        ('u_stu', 'Student User', 'stu.verify+1@ictuniversity.edu.cm', 'student', 'STU001'),
    ]
    for uid, name, email, role, matric in users:
        conn.execute(
            """
            INSERT INTO users (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (uid, name, email, PASS_HASH, matric, 'SEN', '+237600000000', role, now),
        )

    courses = [
        ('c_admin', 'ADM101', 'Admin Managed Course', 'u_admin', 'Admin User', None),
        ('c_super', 'SUP101', 'Super Managed Course', 'u_super', 'Super User', None),
        ('c_lec', 'LEC101', 'Lecturer Managed Course', 'u_lec', 'Lecturer User', None),
        ('c_rep', 'REP101', 'Rep Managed Course', 'u_lec', 'Lecturer User', 'u_rep'),
    ]
    for cid, code, name, lec_id, lec_name, rep_id in courses:
        conn.execute(
            """
            INSERT INTO courses (id, course_code, course_name, lecturer_id, lecturer_display_name, course_rep_id, semester, academic_year)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (cid, code, name, lec_id, lec_name, rep_id, 'Semester 1', 2026),
        )

    conn.commit()

client = TestClient(app)

def auth(uid, role):
    return {'Authorization': f"Bearer {create_access_token(uid, role)}"}

def create_and_close(label, uid, role, course_id, should_pass=True):
    r_create = client.post(
        '/sessions',
        headers=auth(uid, role),
        json={
            'course_id': course_id,
            'class_type': 'normal',
            'scheduled_date': now,
            'classroom_latitude': 3.8667,
            'classroom_longitude': 11.5167,
        },
    )

    create_ok = r_create.status_code == 200
    if not should_pass:
        create_ok = r_create.status_code == 403

    session_id = None
    close_ok = not should_pass

    if should_pass and r_create.status_code == 200:
        session_id = r_create.json().get('session', {}).get('id')
        r_close = client.post(f'/sessions/{session_id}/close', headers=auth(uid, role), json={})
        close_ok = r_close.status_code == 200

    print(f"{label}: create={r_create.status_code}, create_ok={create_ok}, close_ok={close_ok}")
    return create_ok and close_ok

results = []
results.append(create_and_close('admin on c_admin', 'u_admin', 'admin', 'c_admin', True))
results.append(create_and_close('super on c_super', 'u_super', 'super_admin', 'c_super', True))
results.append(create_and_close('lecturer on c_lec', 'u_lec', 'lecturer', 'c_lec', True))
results.append(create_and_close('course_rep on assigned c_rep', 'u_rep', 'course_rep', 'c_rep', True))
results.append(create_and_close('student blocked on c_lec', 'u_stu', 'student', 'c_lec', False))

# Validate /me/courses role visibility relevant to dashboards
for uid, role in [('u_admin', 'admin'), ('u_super', 'super_admin'), ('u_lec', 'lecturer'), ('u_rep', 'course_rep')]:
    r = client.get('/me/courses', headers=auth(uid, role))
    print(f"me/courses {role}: status={r.status_code}, count={len(r.json().get('courses', [])) if r.status_code==200 else 'n/a'}")

all_ok = all(results)
print('RESULT:', 'PASS' if all_ok else 'FAIL')
raise SystemExit(0 if all_ok else 1)

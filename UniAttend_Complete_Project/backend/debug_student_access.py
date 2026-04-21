"""
Debug test: Verify student can access enrolled course sessions.
"""
import os
import uuid
from datetime import datetime

DB_PATH = os.path.join('data', 'debug_student_access.db')
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
os.environ['UNIATTEND_DB_PATH'] = DB_PATH

from app.db import init_db, get_conn
from app.main import app
from app.security import create_access_token
from fastapi.testclient import TestClient

init_db()
now = datetime.utcnow().isoformat()
PASSWORD_HASH = 'pbkdf2_sha256$100000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='

# Setup simple data
with get_conn() as conn:
    # Create users
    conn.execute(
        'INSERT INTO users (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ('u_lec', 'Test Lecturer', 'lec@test.cm', PASSWORD_HASH, 'LEC-001', 'CS', '+237600000000', 'lecturer', now),
    )
    conn.execute(
        'INSERT INTO users (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ('u_stu', 'Test Student', 'stu@test.cm', PASSWORD_HASH, 'STU-001', 'CS', '+237600000000', 'student', now),
    )
    
    # Create course
    conn.execute(
        'INSERT INTO courses (id, course_code, course_name, lecturer_id, lecturer_display_name, semester, academic_year) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        ('c_test', 'TEST101', 'Test Course', 'u_lec', 'Test Lecturer', 'S1', 2026),
    )
    
    # Enroll student
    en_id = f'en_{uuid.uuid4().hex[:10]}'
    conn.execute(
        'INSERT INTO course_enrollments (id, course_id, student_id, created_at) VALUES (?, ?, ?, ?)',
        (en_id, 'c_test', 'u_stu', now),
    )
    
    # Create session
    conn.execute(
        'INSERT INTO attendance_sessions '
        '(id, course_id, class_type, scheduled_date, status, check_in_opened_at, classroom_latitude, classroom_longitude, created_by, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ('sess_test', 'c_test', 'normal', now, 'open_for_check_in', now, 3.8667, 11.5167, 'u_lec', now),
    )
    
    conn.commit()

# Verify data in database
with get_conn() as conn:
    courses = conn.execute('SELECT * FROM courses').fetchall()
    enrollments = conn.execute('SELECT * FROM course_enrollments').fetchall()
    sessions = conn.execute('SELECT * FROM attendance_sessions').fetchall()
    print('\nDATA VERIFICATION:')
    print(f'  Courses: {len(courses)}')
    for r in courses:
        print(f'    - {dict(r)}')
    print(f'  Enrollments: {len(enrollments)}')
    for r in enrollments:
        print(f'    - {dict(r)}')
    print(f'  Sessions: {len(sessions)}')
    for r in sessions:
        print(f'    - {dict(r)}')

client = TestClient(app)

def headers(user_id, role):
    token = create_access_token(user_id=user_id, role=role)
    return {'Authorization': f'Bearer {token}'}

print('\nTEST RESULTS:')
print(f'  Student (u_stu) accessing course sessions for c_test:')
hdrs = headers('u_stu', 'student')
resp = client.get('/sessions/course/c_test', headers=hdrs)
print(f'    GET /sessions/course/c_test -> {resp.status_code}')
if resp.status_code != 200:
    print(f'      Error: {resp.json()}')
else:
    print(f'      Sessions: {resp.json()}')

print(f'\n  Student (u_stu) accessing active session for c_test:')
resp = client.get('/sessions/active/c_test', headers=hdrs)
print(f'    GET /sessions/active/c_test -> {resp.status_code}')
if resp.status_code != 200:
    print(f'      Error: {resp.json()}')

print(f'\n  Student (u_stu) accessing session detail for sess_test:')
resp = client.get('/sessions/sess_test', headers=hdrs)
print(f'    GET /sessions/sess_test -> {resp.status_code}')
if resp.status_code != 200:
    print(f'      Error: {resp.json()}')

print(f'\n  Lecturer (u_lec) accessing course sessions for c_test:')
hdrs = headers('u_lec', 'lecturer')
resp = client.get('/sessions/course/c_test', headers=hdrs)
print(f'    GET /sessions/course/c_test -> {resp.status_code}')

print('\nCONCLUSION:')
if resp.status_code == 200:
    print('  SUCCESS: All endpoints working correctly by role')
else:
    print('  FAILURE: There are permission issues to investigate')

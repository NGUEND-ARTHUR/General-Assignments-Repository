"""
Comprehensive role-functionality matrix test for UniAttend.
Tests every major functionality across all 5 roles: student, course_rep, lecturer, admin, super_admin.
"""
import os
import uuid
from datetime import datetime

DB_PATH = os.path.join('data', 'verify_roles_comprehensive.db')
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)
os.environ['UNIATTEND_DB_PATH'] = DB_PATH

from app.db import init_db, get_conn
from app.main import app
from app.security import create_access_token
from fastapi.testclient import TestClient

init_db()
now = datetime.utcnow().isoformat()

# Seed deterministic test data
users = [
    ('u_admin', 'Admin User', 'admin@test.cm', 'admin', 'ADM-001'),
    ('u_super', 'Super User', 'super@test.cm', 'super_admin', 'SUP-001'),
    ('u_lec1', 'Lecturer One', 'lec1@test.cm', 'lecturer', 'LEC-001'),
    ('u_lec2', 'Lecturer Two', 'lec2@test.cm', 'lecturer', 'LEC-002'),
    ('u_rep1', 'Rep One', 'rep1@test.cm', 'course_rep', 'REP-001'),
    ('u_rep2', 'Rep Two', 'rep2@test.cm', 'course_rep', 'REP-002'),
    ('u_stu1', 'Student One', 'stu1@test.cm', 'student', 'STU-001'),
    ('u_stu2', 'Student Two', 'stu2@test.cm', 'student', 'STU-002'),
]

courses = [
    ('c_lec1', 'CS101', 'Intro to CS', 'u_lec1', 'Lecturer One', 'u_rep1'),
    ('c_lec2', 'CS102', 'Advanced CS', 'u_lec2', 'Lecturer Two', 'u_rep2'),
]

with get_conn() as conn:
    PASSWORD_HASH = 'pbkdf2_sha256$100000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
    for uid, name, email, role, matric in users:
        conn.execute(
            'INSERT INTO users (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            (uid, name, email, PASSWORD_HASH, matric, 'SEN', '+237600000000', role, now),
        )

    for cid, code, cname, lec_id, lec_name, rep_id in courses:
        conn.execute(
            'INSERT INTO courses (id, course_code, course_name, lecturer_id, lecturer_display_name, course_rep_id, semester, academic_year) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            (cid, code, cname, lec_id, lec_name, rep_id, 'Semester 1', 2026),
        )

    # Enroll students
    conn.execute(
        'INSERT INTO course_enrollments (id, course_id, student_id, created_at) VALUES (?, ?, ?, ?)',
        (f'en_{uuid.uuid4().hex[:10]}', 'c_lec1', 'u_stu1', now),
    )
    conn.execute(
        'INSERT INTO course_enrollments (id, course_id, student_id, created_at) VALUES (?, ?, ?, ?)',
        (f'en_{uuid.uuid4().hex[:10]}', 'c_lec2', 'u_stu2', now),
    )

    # Create sessions
    for i, cid in enumerate(['c_lec1', 'c_lec2']):
        conn.execute(
            'INSERT INTO attendance_sessions '
            '(id, course_id, class_type, scheduled_date, status, check_in_opened_at, classroom_latitude, classroom_longitude, created_by, created_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            (f'sess_{i+1}', cid, 'normal', now, 'open_for_check_in', now, 3.8667, 11.5167, 'u_admin', now),
        )

    conn.commit()

client = TestClient(app)

def headers(user_id, role):
    token = create_access_token(user_id=user_id, role=role)
    return {'Authorization': f'Bearer {token}'}

# Define all test cases
tests = [
    # Auth - require ICT University email domain
    ('POST Auth Register', 'POST', '/auth/register', {}, {'full_name': 'Test User', 'email': 'test@ictuniversity.edu.cm', 'password': 'Pass123', 'matric_number': 'TST001', 'department': 'CS'}, {'roles': ['unauthenticated'], 'expected': 201}),
    ('POST Auth Login', 'POST', '/auth/login', {}, {'email': 'admin@ictuniversity.edu.cm', 'password': 'Pass123'}, {'roles': ['unauthenticated'], 'expected': 401}),  # Will fail auth since test user doesn't exist
    
    # Profile
    ('GET My Profile', 'GET', '/auth/me', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    
    # Courses - List & View
    ('GET All Courses', 'GET', '/courses', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    ('GET Courses Catalog', 'GET', '/courses/catalog', {}, {}, {'roles': ['student', 'course_rep'], 'expected': 200}),
    ('GET My Courses', 'GET', '/me/courses', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    
    # Sessions - BEFORE enrollment modifications so student still has access to c_lec1
    ('POST Create Session', 'POST', '/sessions', {}, {'course_id': 'c_lec1', 'class_type': 'normal', 'scheduled_date': now, 'classroom_latitude': 3.8667, 'classroom_longitude': 11.5167}, {'roles': ['lecturer', 'admin', 'super_admin'], 'expected': 201, 'owner': 'u_lec1'}),
    ('GET Sessions List', 'GET', '/sessions/course/c_lec1', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    ('GET Active Session', 'GET', '/sessions/active/c_lec1', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    ('GET Session Detail', 'GET', '/sessions/sess_1', {}, {}, {'roles': ['admin', 'super_admin', 'student'], 'expected': 200}),
    
    # Courses - Management
    ('POST Create Course (Admin)', 'POST', '/courses', {}, {'course_code': 'TEST101', 'course_name': 'Test Course', 'semester': 'S1', 'academic_year': 2026, 'lecturer_identifier': 'u_lec1'}, {'roles': ['admin'], 'expected': 200}),
    ('POST Create Course (SuperAdmin) - Duplicate', 'POST', '/courses', {}, {'course_code': 'TEST101', 'course_name': 'Test Course 2', 'semester': 'S1', 'academic_year': 2026, 'lecturer_identifier': 'u_lec2'}, {'roles': ['super_admin'], 'expected': 409}),  # Expected: conflict on duplicate course code
    ('POST Enroll Course', 'POST', '/me/courses/c_lec2', {}, {}, {'roles': ['student'], 'expected': 200}),
    ('DELETE Unenroll', 'DELETE', '/me/courses/c_lec2', {}, {}, {'roles': ['student'], 'expected': 200}),  # Unenroll from c_lec2, keep c_lec1
    ('POST Open Checkout', 'POST', '/sessions/sess_1/open-checkout', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep'], 'expected': 200, 'owner': 'u_lec1'}),
    ('POST Close Session', 'POST', '/sessions/sess_1/close', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep'], 'expected': 200, 'owner': 'u_lec1'}),
    
    # Attendance
    ('POST Check In', 'POST', '/attendance/checkin', {}, {'session_id': 'sess_1', 'student_id': 'u_stu1', 'device_id': 'dev123', 'latitude': 3.8667, 'longitude': 11.5167}, {'roles': ['student'], 'expected': 400}),
    ('GET Session Attendance', 'GET', '/attendance/session/sess_1', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep'], 'expected': 200, 'owner': 'u_lec1'}),
    ('GET My Attendance', 'GET', '/attendance/me', {}, {}, {'roles': ['student'], 'expected': 200}),
    
    # Analytics
    ('GET Dashboard', 'GET', '/analytics/dashboard', {}, {}, {'roles': ['admin', 'super_admin', 'lecturer'], 'expected': 200}),
    
    # Admin
    ('GET Role Applications', 'GET', '/admin/role-applications', {}, {}, {'roles': ['super_admin'], 'expected': 200}),  # Admin cannot access (restricted to super_admin only)
]

print("\n" + "="*120)
print("COMPREHENSIVE ROLE-FUNCTIONALITY TEST MATRIX FOR ALL ROLES")
print("="*120)

results = {role: {'passed': 0, 'failed': 0, 'errors': []} for role in ['admin', 'super_admin', 'lecturer', 'course_rep', 'student']}
unauth_results = {'passed': 0, 'failed': 0, 'errors': []}

for test_name, method, path, params, body, config in tests:
    allowed_roles = config.get('roles', [])
    expected = config.get('expected', 200)
    is_unauth = 'unauthenticated' in allowed_roles

    if is_unauth:
        try:
            if method == 'GET':
                r = client.get(path)
            elif method == 'POST':
                r = client.post(path, json=body or {})
            else:
                r = client.request(method, path, json=body or {})
            
            ok = r.status_code == expected or (expected in [200, 201] and r.status_code in [200, 201])
            status = 'PASS' if ok else 'FAIL'
            print(f"  [{status:4}] {test_name:35} (unauthenticated) -> {r.status_code}")
            if ok:
                unauth_results['passed'] += 1
            else:
                unauth_results['failed'] += 1
                unauth_results['errors'].append(f"{test_name}: {r.status_code} != {expected}")
        except Exception as e:
            print(f"  [ERR ] {test_name:35} (unauthenticated) -> {str(e)[:40]}")
            unauth_results['failed'] += 1
            unauth_results['errors'].append(f"{test_name}: {str(e)[:50]}")
    else:
        for role in allowed_roles:
            user_map = {'admin': 'u_admin', 'super_admin': 'u_super', 'lecturer': 'u_lec1', 'course_rep': 'u_rep1', 'student': 'u_stu1'}
            user_id = user_map.get(role, f'u_{role}')
            
            # Override user for certain tests
            if config.get('owner') == 'u_lec1' and role == 'lecturer':
                user_id = 'u_lec1'
            elif config.get('owner') == 'u_lec1' and role == 'course_rep':
                user_id = 'u_rep1'
            
            try:
                hdrs = headers(user_id, role)
                if method == 'GET':
                    r = client.get(path, headers=hdrs)
                elif method == 'POST':
                    r = client.post(path, json=body or {}, headers=hdrs)
                elif method == 'DELETE':
                    r = client.delete(path, headers=hdrs)
                else:
                    r = client.request(method, path, json=body or {}, headers=hdrs)
                
                ok = r.status_code == expected or (expected in [200, 201] and r.status_code in [200, 201])
                if expected in [400, 403, 404, 409]:
                    ok = r.status_code == expected
                
                status = 'PASS' if ok else 'FAIL'
                print(f"  [{status:4}] {test_name:35} ({role:12}) -> {r.status_code}")
                
                if ok:
                    results[role]['passed'] += 1
                else:
                    results[role]['failed'] += 1
                    results[role]['errors'].append(f"{test_name}: {r.status_code} != {expected}")
            except Exception as e:
                print(f"  [ERR ] {test_name:35} ({role:12}) -> {str(e)[:30]}")
                results[role]['failed'] += 1
                results[role]['errors'].append(f"{test_name}: {str(e)[:40]}")

print("\n" + "="*120)
print("SUMMARY BY ROLE")
print("="*120)

for role in ['admin', 'super_admin', 'lecturer', 'course_rep', 'student']:
    p = results[role]['passed']
    f = results[role]['failed']
    t = p + f
    pct = (p / t * 100) if t > 0 else 0
    status = 'PASS' if f == 0 else 'FAIL'
    print(f"[{status:4}] {role:15} | {p:2}/{t:2} passed ({pct:5.1f}%)")
    if results[role]['errors']:
        for e in results[role]['errors'][:2]:
            print(f"       - {e}")

up = unauth_results['passed']
uf = unauth_results['failed']
ut = up + uf
upct = (up / ut * 100) if ut > 0 else 0
status = 'PASS' if uf == 0 else 'FAIL'
print(f"[{status:4}] {'unauthenticated':15} | {up:2}/{ut:2} passed ({upct:5.1f}%)")

total_p = sum(r['passed'] for r in results.values()) + up
total_f = sum(r['failed'] for r in results.values()) + uf
print(f"\n{'='*120}")
print(f"TOTAL: {total_p} PASSED, {total_f} FAILED")
if total_f > 0:
    print("OVERALL: FAIL")
    exit(1)
else:
    print("OVERALL: PASS")
    exit(0)

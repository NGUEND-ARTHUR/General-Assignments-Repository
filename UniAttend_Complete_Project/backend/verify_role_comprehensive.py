"""
Comprehensive role-functionality matrix test for UniAttend.
Tests every major endpoint across all roles to verify authorization and correct behavior.
"""
import os
import uuid
import json
from datetime import datetime, timedelta

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

# Courses: owned by lecturers, with assigned course reps
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

    # Enroll students in courses
    conn.execute(
        'INSERT INTO course_enrollments (id, course_id, student_id, created_at) VALUES (?, ?, ?, ?)',
        (f'en_{uuid.uuid4().hex[:10]}', 'c_lec1', 'u_stu1', now),
    )
    conn.execute(
        'INSERT INTO course_enrollments (id, course_id, student_id, created_at) VALUES (?, ?, ?, ?)',
        (f'en_{uuid.uuid4().hex[:10]}', 'c_lec2', 'u_stu2', now),
    )

    # Create attendance sessions
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

# Test Matrix: [endpoint, method, path_params, body, allowed_roles, expected_success]
tests = [
    # === Auth Endpoints ===
    ('POST Auth Register', 'POST', '/auth/register', {}, {},
     {'roles': ['unauthenticated'], 'expected': 201, 'test_user': True}),
    ('POST Auth Login', 'POST', '/auth/login', {}, {},
     {'roles': ['unauthenticated'], 'expected': 200, 'test_user': True}),

    # === Profile Endpoints ===
    ('GET My Profile', 'GET', '/auth/me', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),

    # === Course Endpoints ===
    ('GET All Courses', 'GET', '/courses', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    ('GET Course Catalog', 'GET', '/courses/catalog', {}, {},
     {'roles': ['student', 'course_rep'], 'expected': 200}),
    ('GET My Courses', 'GET', '/me/courses', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    ('POST Create Course', 'POST', '/courses', {}, {'course_code': 'NEW101', 'course_name': 'New Course', 'semester': 'Semester 1', 'academic_year': 2026, 'lecturer_identifier': 'u_lec1'},
     {'roles': ['admin', 'super_admin'], 'expected': 200}),

    # === Enrollment Endpoints ===
    ('POST Enroll in Course', 'POST', '/me/courses/c_lec2', {}, {},
     {'roles': ['student'], 'expected': 200, 'enroll_student': 'u_stu1'}),
    ('DELETE Unenroll from Course', 'DELETE', '/me/courses/c_lec1', {}, {},
     {'roles': ['student'], 'expected': 200}),

    # === Attendance Session Endpoints ===
    ('POST Create Session', 'POST', '/sessions', {}, {'course_id': 'c_lec1', 'class_type': 'normal', 'scheduled_date': now},
     {'roles': ['lecturer', 'admin', 'super_admin'], 'expected': 201, 'owned_by': 'u_lec1'}),
    ('GET Sessions for Course', 'GET', '/sessions/course/c_lec1', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    ('GET Active Session', 'GET', '/sessions/active/c_lec1', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep', 'student'], 'expected': 200}),
    ('GET Session Detail', 'GET', '/sessions/sess_1', {}, {},
     {'roles': ['admin', 'super_admin', 'student'], 'expected': 200}),
    ('POST Open Checkout', 'POST', '/sessions/sess_1/open-checkout', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep'], 'expected': 200, 'owned_by': 'u_lec1'}),
    ('POST Close Session', 'POST', '/sessions/sess_1/close', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep'], 'expected': 200, 'owned_by': 'u_lec1'}),

    # === Check-in Endpoints ===
    ('POST Check In', 'POST', '/attendance/checkin', {}, {'session_id': 'sess_1', 'qr_token': 'fake_qr_token'},
     {'roles': ['student'], 'expected': 400}),  # Will fail due to invalid token, but tests auth

    # === Attendance Records ===
    ('GET Session Attendance', 'GET', '/attendance/session/sess_1', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer', 'course_rep'], 'expected': 200, 'owned_by': 'u_lec1'}),
    ('GET My Attendance', 'GET', '/attendance/me', {}, {},
     {'roles': ['student'], 'expected': 200}),

    # === Analytics Endpoints ===
    ('GET Analytics Dashboard', 'GET', '/analytics/dashboard', {}, {},
     {'roles': ['admin', 'super_admin', 'lecturer'], 'expected': 200}),

    # === Admin Endpoints ===
    ('GET Role Applications', 'GET', '/admin/role-applications', {}, {},
     {'roles': ['admin', 'super_admin'], 'expected': 200}),
]

client.base_url = "http://testserver"

print("\n" + "="*100)
print("COMPREHENSIVE ROLE-FUNCTIONALITY TEST MATRIX")
print("="*100)

results = {role: {'passed': 0, 'failed': 0, 'details': []} for role in ['admin', 'super_admin', 'lecturer', 'course_rep', 'student']}
unauthenticated_results = {'passed': 0, 'failed': 0, 'details': []}

for test_name, method, path, path_params, body, config in tests:
    allowed_roles = config.get('roles', [])
    expected_status = config.get('expected', 200)
    is_unauthenticated = 'unauthenticated' in allowed_roles

    # Determine actual path
    actual_path = path.format(**path_params) if path_params else path

    if is_unauthenticated:
        # Test without auth
        try:
            if method == 'GET':
                resp = client.get(actual_path)
            elif method == 'POST':
                resp = client.post(actual_path, json=body or {})
            elif method == 'PUT':
                resp = client.put(actual_path, json=body or {})
            else:
                resp = client.request(method, actual_path, json=body or {})

            status = resp.status_code
            ok = status == expected_status or (expected_status == 201 and status == 200)
            mark = '✓ PASS' if ok else '✗ FAIL'
            detail = f"{mark} | {test_name} (unauthenticated) -> {status} (expected {expected_status})"
            print(f"  {detail}")
            if ok:
                unauthenticated_results['passed'] += 1
            else:
                unauthenticated_results['failed'] += 1
                unauthenticated_results['details'].append(detail)
        except Exception as e:
            detail = f"✗ FAIL | {test_name} (unauthenticated) -> Exception: {str(e)}"
            print(f"  {detail}")
            unauthenticated_results['failed'] += 1
            unauthenticated_results['details'].append(detail)
    else:
        # Test for each allowed role
        for role in allowed_roles:
            # Determine which user to test with
            test_users = {
                'admin': 'u_admin',
                'super_admin': 'u_super',
                'lecturer': 'u_lec1' if config.get('owned_by') == 'u_lec1' else 'u_lec2',
                'course_rep': 'u_rep1' if config.get('owned_by') == 'u_lec1' else 'u_rep2',
                'student': 'u_stu1' if config.get('enroll_student') != 'u_stu1' else 'u_stu2',
            }
            user_id = test_users.get(role, f'u_{role}')

            try:
                hdrs = headers(user_id, role)
                if method == 'GET':
                    resp = client.get(actual_path, headers=hdrs)
                elif method == 'POST':
                    resp = client.post(actual_path, json=body or {}, headers=hdrs)
                elif method == 'PUT':
                    resp = client.put(actual_path, json=body or {}, headers=hdrs)
                else:
                    resp = client.request(method, actual_path, json=body or {}, headers=hdrs)

                status = resp.status_code
                ok = status == expected_status or (expected_status in [201, 200] and status in [201, 200])
                if expected_status == 409:  # Special case for expected failures
                    ok = status == expected_status

                mark = '✓ PASS' if ok else '✗ FAIL'
                detail = f"{mark} | {test_name} ({role:12}) -> {status} (expected {expected_status})"
                print(f"  {detail}")

                if ok:
                    results[role]['passed'] += 1
                else:
                    results[role]['failed'] += 1
                    results[role]['details'].append(detail)
                    try:
                        print(f"       Response: {resp.json().get('detail', resp.text[:100])}")
                    except:
                        print(f"       Response: {resp.text[:100]}")

            except Exception as e:
                detail = f"✗ FAIL | {test_name} ({role:12}) -> Exception: {str(e)}"
                print(f"  {detail}")
                results[role]['failed'] += 1
                results[role]['details'].append(detail)

print("\n" + "="*100)
print("SUMMARY")
print("="*100)

for role in ['admin', 'super_admin', 'lecturer', 'course_rep', 'student']:
    passed = results[role]['passed']
    failed = results[role]['failed']
    total = passed + failed
    pct = (passed / total * 100) if total > 0 else 0
    status = '✓ PASS' if failed == 0 else '✗ FAIL'
    print(f"{status} | {role:15} | Passed: {passed:2}/{total:2} ({pct:5.1f}%)")
    if results[role]['details']:
        for detail in results[role]['details'][:3]:
            print(f"        {detail}")

unauthenticated_passed = unauthenticated_results['passed']
unauthenticated_failed = unauthenticated_results['failed']
unauthenticated_total = unauthenticated_passed + unauthenticated_failed
unauthenticated_pct = (unauthenticated_passed / unauthenticated_total * 100) if unauthenticated_total > 0 else 0
status = '✓ PASS' if unauthenticated_failed == 0 else '✗ FAIL'
print(f"{status} | {'unauthenticated':15} | Passed: {unauthenticated_passed:2}/{unauthenticated_total:2} ({unauthenticated_pct:5.1f}%)")

total_passed = sum(r['passed'] for r in results.values()) + unauthenticated_results['passed']
total_failed = sum(r['failed'] for r in results.values()) + unauthenticated_results['failed']
print(f"\n{'='*100}")
print(f"TOTAL: {total_passed} passed, {total_failed} failed")
if total_failed > 0:
    print("RESULT: FAIL")
    raise SystemExit(1)
else:
    print("RESULT: PASS")
    raise SystemExit(0)

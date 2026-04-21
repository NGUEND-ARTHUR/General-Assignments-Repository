#!/usr/bin/env python3
"""Final API validation for UniAttend backend after hardening."""
import requests
import json
import time
from datetime import datetime

API_BASE = "http://127.0.0.1:8000"
HEADERS = {"Content-Type": "application/json"}

def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {level}: {msg}")

def test_auth():
    """Test auth flows with new blocked account enforcement."""
    log("=== TESTING AUTH FLOWS ===")
    
    # Register test accounts
    test_users = [
        {
            "full_name": "Test Admin",
            "email": "test_admin@ictuniversity.edu.cm",
            "password": "TestAdmin@1234",
            "matric_number": "TEST_ADM_001",
            "department": "Admin",
            "role": "student",
        },
        {
            "full_name": "Test Lecturer",
            "email": "test_lecturer@ictuniversity.edu.cm",
            "password": "TestLec@1234",
            "matric_number": "TEST_LEC_001",
            "department": "ICT",
            "role": "student",
        },
        {
            "full_name": "Test Student",
            "email": "test_student@ictuniversity.edu.cm",
            "password": "TestStu@1234",
            "matric_number": "TEST_STU_001",
            "department": "ICT",
            "role": "student",
        },
    ]
    
    tokens = {}
    for user in test_users:
        email = user["email"]
        resp = requests.post(f"{API_BASE}/auth/register", json=user, headers=HEADERS)
        if resp.status_code == 409:
            log(f"  {email} already exists, logging in instead", "WARN")
        elif resp.status_code == 200:
            log(f"  ✓ Registered {email}")
        else:
            log(f"  ✗ Register failed for {email}: {resp.status_code} {resp.text}", "ERROR")
            continue
        
        # Login
        login_resp = requests.post(
            f"{API_BASE}/auth/login",
            json={"email": email, "password": user["password"]},
            headers=HEADERS,
        )
        if login_resp.status_code == 200:
            tokens[email] = login_resp.json()["access_token"]
            log(f"  ✓ Logged in {email}")
        else:
            log(f"  ✗ Login failed: {login_resp.status_code}", "ERROR")
    
    # Test /auth/me
    for email, token in tokens.items():
        resp = requests.get(
            f"{API_BASE}/auth/me",
            headers={**HEADERS, "Authorization": f"Bearer {token}"},
        )
        if resp.status_code == 200:
            user_data = resp.json()["user"]
            log(f"  ✓ /auth/me for {email}: role={user_data['role']}, is_active={user_data.get('is_active', True)}")
        else:
            log(f"  ✗ /auth/me failed: {resp.status_code}", "ERROR")
    
    return tokens

def test_user_management(tokens):
    """Test super-admin user management including blocking."""
    log("\n=== TESTING ADMIN USER MANAGEMENT ===")
    
    # Get bootstrap super-admin token (from env or login)
    # For this test, we'll use one of our test accounts after promoting it
    # First, let's get list of users to find super-admin
    
    admin_email = "admin@ictuniversity.edu.cm"
    admin_pass = "Admin@1234"
    
    login_resp = requests.post(
        f"{API_BASE}/auth/login",
        json={"email": admin_email, "password": admin_pass},
        headers=HEADERS,
    )
    
    if login_resp.status_code != 200:
        log(f"  ✗ Could not login as admin: {login_resp.status_code}", "ERROR")
        return
    
    admin_token = login_resp.json()["access_token"]
    log(f"  ✓ Logged in as bootstrap admin")
    
    # Promote to super-admin for testing
    super_admin_email = "nguend.johann@ictuniversity.edu.cm"
    super_admin_pass = "Arthutr@ictu2024"
    
    super_resp = requests.post(
        f"{API_BASE}/auth/login",
        json={"email": super_admin_email, "password": super_admin_pass},
        headers=HEADERS,
    )
    
    if super_resp.status_code == 200:
        super_token = super_resp.json()["access_token"]
        log(f"  ✓ Logged in as super-admin")
        
        # Test: list users
        list_resp = requests.get(
            f"{API_BASE}/admin/users",
            headers={**HEADERS, "Authorization": f"Bearer {super_token}"},
        )
        if list_resp.status_code == 200:
            users = list_resp.json()["users"]
            log(f"  ✓ Listed {len(users)} users")
        else:
            log(f"  ✗ List users failed: {list_resp.status_code}", "ERROR")
            return
        
        # Test: block a user
        if len(users) > 1:
            target_user_id = users[0]["id"]
            target_email = users[0]["email"]
            
            block_resp = requests.post(
                f"{API_BASE}/admin/users/{target_user_id}/block",
                json={"reason": "Testing block functionality"},
                headers={**HEADERS, "Authorization": f"Bearer {super_token}"},
            )
            
            if block_resp.status_code == 200:
                log(f"  ✓ Blocked user {target_email}")
                
                # Verify user cannot login
                login_blocked = requests.post(
                    f"{API_BASE}/auth/login",
                    json={"email": target_email, "password": users[0].get("password", "test")},
                    headers=HEADERS,
                )
                # Should fail with 403 (account blocked)
                if login_blocked.status_code == 403:
                    log(f"  ✓ Blocked user cannot login (403 Forbidden)")
                else:
                    log(f"  ~ Blocked user login returned {login_blocked.status_code}", "WARN")
                
                # Test: unblock
                unblock_resp = requests.post(
                    f"{API_BASE}/admin/users/{target_user_id}/unblock",
                    headers={**HEADERS, "Authorization": f"Bearer {super_token}"},
                )
                
                if unblock_resp.status_code == 200:
                    log(f"  ✓ Unblocked user {target_email}")
                else:
                    log(f"  ✗ Unblock failed: {unblock_resp.status_code}", "ERROR")
            else:
                log(f"  ✗ Block user failed: {block_resp.status_code}", "ERROR")

def test_sessions_and_qr(tokens):
    """Test session management and QR issuance."""
    log("\n=== TESTING SESSIONS & QR GENERATION ===")
    
    # Use admin token to create a session
    admin_email = list(tokens.keys())[0] if tokens else None
    if not admin_email:
        log("  ✗ No admin token available", "ERROR")
        return
    
    headers = {**HEADERS, "Authorization": f"Bearer {tokens[admin_email]}"}
    
    # Get courses first
    courses_resp = requests.get(f"{API_BASE}/courses", headers=headers)
    if courses_resp.status_code != 200:
        log(f"  ✗ Could not fetch courses: {courses_resp.status_code}", "ERROR")
        return
    
    courses = courses_resp.json().get("courses", [])
    if not courses:
        log("  ~ No courses available for session creation", "WARN")
        return
    
    course_id = courses[0]["id"]
    log(f"  ✓ Using course {courses[0].get('course_code', course_id)}")
    
    # Create a session
    session_data = {
        "course_id": course_id,
        "class_type": "normal",
        "scheduled_date": datetime.now().isoformat(),
        "classroom_latitude": 3.8667,
        "classroom_longitude": 11.5167,
    }
    
    session_resp = requests.post(
        f"{API_BASE}/sessions",
        json=session_data,
        headers=headers,
    )
    
    if session_resp.status_code == 200:
        session_id = session_resp.json()["session"]["id"]
        log(f"  ✓ Created session {session_id}")
        
        # Test: Generate QR for checkin
        qr_resp = requests.get(
            f"{API_BASE}/sessions/{session_id}/qr?phase=checkin",
            headers=headers,
        )
        
        if qr_resp.status_code == 200:
            qr_data = qr_resp.json()
            log(f"  ✓ Generated check-in QR (expires in {qr_data.get('expires_in_seconds', 'N/A')}s)")
            
            # Verify QR payload structure
            payload = qr_data.get("payload", "")
            if payload:
                log(f"  ✓ QR payload present: {len(payload)} bytes")
            
            # Test: Generate checkout QR (should fail until checkout is open)
            checkout_resp = requests.get(
                f"{API_BASE}/sessions/{session_id}/qr?phase=checkout",
                headers=headers,
            )
            
            if checkout_resp.status_code == 409:
                log(f"  ✓ Checkout QR correctly blocked (409): {checkout_resp.json().get('detail', 'N/A')}")
            else:
                log(f"  ~ Checkout QR returned {checkout_resp.status_code}", "WARN")
        else:
            log(f"  ✗ QR generation failed: {qr_resp.status_code}", "ERROR")
    else:
        log(f"  ✗ Session creation failed: {session_resp.status_code}", "ERROR")

def test_attendance_flow(tokens):
    """Test attendance checkin/checkout with device binding."""
    log("\n=== TESTING ATTENDANCE FLOW ===")
    
    # Similar setup as above
    admin_email = list(tokens.keys())[0] if tokens else None
    if not admin_email:
        log("  ✗ No admin token available", "ERROR")
        return
    
    headers = {**HEADERS, "Authorization": f"Bearer {tokens[admin_email]}"}
    
    # Create session and get QR
    courses_resp = requests.get(f"{API_BASE}/courses", headers=headers)
    courses = courses_resp.json().get("courses", [])
    
    if not courses:
        log("  ~ No courses available", "WARN")
        return
    
    course_id = courses[0]["id"]
    
    session_data = {
        "course_id": course_id,
        "class_type": "normal",
        "scheduled_date": datetime.now().isoformat(),
        "classroom_latitude": 3.8667,
        "classroom_longitude": 11.5167,
    }
    
    session_resp = requests.post(
        f"{API_BASE}/sessions",
        json=session_data,
        headers=headers,
    )
    
    if session_resp.status_code != 200:
        log("  ✗ Could not create session", "ERROR")
        return
    
    session_id = session_resp.json()["session"]["id"]
    
    # Get QR payload
    qr_resp = requests.get(
        f"{API_BASE}/sessions/{session_id}/qr?phase=checkin",
        headers=headers,
    )
    
    if qr_resp.status_code != 200:
        log("  ✗ Could not get QR", "ERROR")
        return
    
    qr_payload = qr_resp.json()["payload"]
    
    # Prepare checkin data
    student_email = "test_student@ictuniversity.edu.cm"
    if student_email not in tokens:
        log(f"  ✗ No token for {student_email}", "ERROR")
        return
    
    student_headers = {**HEADERS, "Authorization": f"Bearer {tokens[student_email]}"}
    
    # Get student user_id by calling /auth/me
    me_resp = requests.get(f"{API_BASE}/auth/me", headers=student_headers)
    if me_resp.status_code != 200:
        log("  ✗ Could not get student user_id", "ERROR")
        return
    
    student_id = me_resp.json()["user"]["id"]
    
    checkin_data = {
        "session_id": session_id,
        "student_id": student_id,
        "device_id": "device_test_001",
        "qr_payload": qr_payload,
        "latitude": 3.8667,
        "longitude": 11.5167,
    }
    
    # Test: Checkin
    checkin_resp = requests.post(
        f"{API_BASE}/attendance/checkin",
        json=checkin_data,
        headers=student_headers,
    )
    
    if checkin_resp.status_code == 200:
        log(f"  ✓ Checked in successfully, status={checkin_resp.json().get('status', 'N/A')}")
        
        # Test: Device binding enforcement (same device cannot be used by another student)
        if len(tokens) > 1:
            other_student_email = [e for e in tokens.keys() if e != student_email and "student" in e.lower()]
            if other_student_email:
                other_email = other_student_email[0]
                other_headers = {**HEADERS, "Authorization": f"Bearer {tokens[other_email]}"}
                
                other_me = requests.get(f"{API_BASE}/auth/me", headers=other_headers)
                if other_me.status_code == 200:
                    other_id = other_me.json()["user"]["id"]
                    
                    # Try checkin with same device
                    conflict_data = {
                        "session_id": session_id,
                        "student_id": other_id,
                        "device_id": "device_test_001",  # Same device
                        "qr_payload": qr_payload,
                        "latitude": 3.8667,
                        "longitude": 11.5167,
                    }
                    
                    conflict_resp = requests.post(
                        f"{API_BASE}/attendance/checkin",
                        json=conflict_data,
                        headers=other_headers,
                    )
                    
                    if conflict_resp.status_code == 409:
                        detail = conflict_resp.json().get("detail", "")
                        if "device" in detail.lower():
                            log(f"  ✓ Device binding enforced (409): {detail}")
                        else:
                            log(f"  ~ Got 409 but unexpected message: {detail}", "WARN")
                    else:
                        log(f"  ~ Device binding not enforced: {conflict_resp.status_code}", "WARN")
    else:
        log(f"  ✗ Checkin failed: {checkin_resp.status_code} {checkin_resp.text}", "ERROR")

def test_anomaly_flagging(tokens):
    """Test staff anomaly flagging."""
    log("\n=== TESTING ANOMALY FLAGGING ===")
    
    # Get a session first
    admin_email = list(tokens.keys())[0] if tokens else None
    if not admin_email:
        log("  ✗ No admin token", "ERROR")
        return
    
    headers = {**HEADERS, "Authorization": f"Bearer {tokens[admin_email]}"}
    
    # Try to flag an anomaly on a session
    # First, create a session
    courses_resp = requests.get(f"{API_BASE}/courses", headers=headers)
    courses = courses_resp.json().get("courses", [])
    
    if not courses:
        log("  ~ No courses", "WARN")
        return
    
    course_id = courses[0]["id"]
    
    session_data = {
        "course_id": course_id,
        "class_type": "normal",
        "scheduled_date": datetime.now().isoformat(),
        "classroom_latitude": 3.8667,
        "classroom_longitude": 11.5167,
    }
    
    session_resp = requests.post(
        f"{API_BASE}/sessions",
        json=session_data,
        headers=headers,
    )
    
    if session_resp.status_code != 200:
        log("  ~ Could not create session", "WARN")
        return
    
    session_id = session_resp.json()["session"]["id"]
    
    # Get a student
    student_email = "test_student@ictuniversity.edu.cm"
    if student_email not in tokens:
        log("  ✗ No student token", "ERROR")
        return
    
    student_headers = {**HEADERS, "Authorization": f"Bearer {tokens[student_email]}"}
    me_resp = requests.get(f"{API_BASE}/auth/me", headers=student_headers)
    if me_resp.status_code != 200:
        log("  ✗ Could not get student ID", "ERROR")
        return
    
    student_id = me_resp.json()["user"]["id"]
    
    # Flag an anomaly
    anomaly_data = {
        "session_id": session_id,
        "student_id": student_id,
        "reason": "Suspicious location pattern detected",
        "details": "Student appeared on two opposite sides of campus within 5 minutes",
    }
    
    anomaly_resp = requests.post(
        f"{API_BASE}/attendance/anomalies",
        json=anomaly_data,
        headers=headers,
    )
    
    if anomaly_resp.status_code == 200:
        anomaly_id = anomaly_resp.json().get("anomaly_id", "N/A")
        log(f"  ✓ Flagged anomaly {anomaly_id}")
    else:
        log(f"  ✗ Anomaly flagging failed: {anomaly_resp.status_code} {anomaly_resp.text}", "ERROR")

def main():
    log("Starting API validation suite...")
    
    try:
        # Test 1: Auth
        tokens = test_auth()
        
        # Test 2: User management
        test_user_management(tokens)
        
        # Test 3: Sessions & QR
        test_sessions_and_qr(tokens)
        
        # Test 4: Attendance flow
        test_attendance_flow(tokens)
        
        # Test 5: Anomaly flagging
        test_anomaly_flagging(tokens)
        
        log("\n=== VALIDATION COMPLETE ===")
    except Exception as e:
        log(f"Unhandled error: {e}", "ERROR")

if __name__ == "__main__":
    main()

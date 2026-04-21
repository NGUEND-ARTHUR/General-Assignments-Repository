#!/usr/bin/env python3
"""Debug check-in endpoint issue"""
import requests
import json

API_BASE = "http://127.0.0.1:8000"

def log(msg, level="INFO"):
    print(f"[{level}] {msg}")

# 1. Login as student
log("1. Logging in as student...")
student_login = requests.post(f"{API_BASE}/auth/login", json={
    "email": "student@ictuniversity.edu.cm",
    "password": "Student@1234"
}).json()
student_token = student_login["access_token"]
student_id = student_login["user"]["id"]
log(f"   Student ID: {student_id}")

# 2. Get lecturer's courses
log("2. Getting lecturer's courses...")
lecturer_login = requests.post(f"{API_BASE}/auth/login", json={
    "email": "lecturer@ictuniversity.edu.cm",
    "password": "Lect@1234"
}).json()
lecturer_token = lecturer_login["access_token"]

courses = requests.get(f"{API_BASE}/courses", headers={
    "Authorization": f"Bearer {lecturer_token}"
}).json()
course_id = courses["courses"][0]["id"]
log(f"   Course ID: {course_id}")

# 3. Enroll student in course
log("3. Enrolling student in course...")
enroll_resp = requests.post(f"{API_BASE}/me/courses/{course_id}", headers={
    "Authorization": f"Bearer {student_token}"
})
log(f"   Enroll status: {enroll_resp.status_code}")
if enroll_resp.status_code != 200:
    log(f"   Error: {enroll_resp.text}", "ERROR")

# 4. Create session
log("4. Creating session...")
from datetime import datetime
session_resp = requests.post(f"{API_BASE}/sessions", headers={
    "Authorization": f"Bearer {lecturer_token}"
}, json={
    "course_id": course_id,
    "class_type": "normal",
    "scheduled_date": datetime.utcnow().isoformat(),
    "classroom_latitude": 3.8667,
    "classroom_longitude": 11.5167
})
log(f"   Session create status: {session_resp.status_code}")
if session_resp.status_code != 200:
    log(f"   Error: {session_resp.text}", "ERROR")
else:
    session = session_resp.json()["session"]
    session_id = session["id"]
    log(f"   Session ID: {session_id}")
    log(f"   Session status: {session.get('status')}")

# 5. Try check-in
log("5. Attempting check-in...")
checkin_resp = requests.post(f"{API_BASE}/attendance/checkin", headers={
    "Authorization": f"Bearer {student_token}"
}, json={
    "session_id": session_id,
    "student_id": student_id,
    "device_id": "test-device-001",
    "latitude": 3.8667,
    "longitude": 11.5167
})

log(f"   Check-in status: {checkin_resp.status_code}")
log(f"   Response: {checkin_resp.text}")

if checkin_resp.status_code != 200:
    log(f"   FAILED - Status code is not 200", "ERROR")
else:
    data = checkin_resp.json()
    log(f"   SUCCESS - Status: {data.get('status')}")

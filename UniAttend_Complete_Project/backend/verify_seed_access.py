import requests

BASE_URL = "https://bios-multimedia-integral-brings.trycloudflare.com"

accounts = [
    ("super_admin", "nguend.johann@ictuniversity.edu.cm", "Arthur@ictu2024"),
    ("admin", "admin@ictuniversity.edu.cm", "Demo@1234"),
    ("lecturer_moune", "engr.moune@ictuniversity.edu.cm", "Demo@1234"),
    ("course_delegate_1", "madonge.jeanne.lesline@ictuniversity.edu.cm", "Demo@1234"),
    ("course_delegate_2", "yemele.tane.loic@ictuniversity.edu.cm", "Demo@1234"),
]


def login(email: str, password: str) -> str:
    r = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": password},
        timeout=20,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def auth_get(path: str, token: str):
    return requests.get(
        f"{BASE_URL}{path}",
        headers={"Authorization": f"Bearer {token}"},
        timeout=20,
    )


if __name__ == "__main__":
    print("Verifying seeded SEN3242 role access...")
    for label, email, password in accounts:
        token = login(email, password)
        courses_resp = auth_get("/courses", token)
        courses_resp.raise_for_status()
        courses = courses_resp.json().get("courses", [])
        sen = next((c for c in courses if (c.get("course_code") or "").upper() == "SEN3242"), None)
        if not sen:
            raise RuntimeError(f"{label}: SEN3242 not visible")

        course_id = sen["id"]
        sessions_resp = auth_get(f"/sessions/course/{course_id}", token)
        sessions_resp.raise_for_status()
        sessions = sessions_resp.json().get("sessions", [])
        if not sessions:
            raise RuntimeError(f"{label}: no sessions found for SEN3242")

        session_id = sessions[0]["id"]
        attendance_resp = auth_get(f"/attendance/session/{session_id}", token)
        attendance_resp.raise_for_status()
        attendance = attendance_resp.json()
        records = attendance.get("records", [])

        print(f"[OK] {label}: course={course_id}, session={session_id}, records={len(records)}")

    print("All target roles can access seeded SEN3242 attendance data.")

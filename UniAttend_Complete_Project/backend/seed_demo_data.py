from __future__ import annotations

import re
import uuid
from datetime import datetime, timedelta

from app.db import get_conn
from app.security import hash_password

DEFAULT_PASSWORD = "Demo@1234"
EMAIL_DOMAIN = "ictuniversity.edu.cm"
NOW = datetime.utcnow()


def _slug(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    return cleaned[:40] or f"id_{uuid.uuid4().hex[:8]}"


def _email_for_name(name: str) -> str:
    base = _slug(name).replace("_", ".")
    return f"{base}@{EMAIL_DOMAIN}"


def _user_id(prefix: str, name: str) -> str:
    return f"{prefix}_{_slug(name)}"[:48]


def _upsert_user(conn, *, user_id: str, full_name: str, email: str, matric: str, department: str, role: str) -> str:
    existing = conn.execute(
        "SELECT id FROM users WHERE lower(email) = lower(?)",
        (email,),
    ).fetchone()

    now = NOW.isoformat()
    hashed = hash_password(DEFAULT_PASSWORD)

    if existing:
        conn.execute(
            """
            UPDATE users
            SET full_name = ?,
                email = ?,
                password_hash = ?,
                matric_number = ?,
                department = ?,
                role = ?,
                is_active = 1,
                blocked_at = NULL,
                blocked_reason = NULL
            WHERE id = ?
            """,
            (full_name, email, hashed, matric, department, role, existing["id"]),
        )
        return existing["id"]

    conn.execute(
        """
        INSERT INTO users
        (id, full_name, email, password_hash, matric_number, department, phone_number, role, created_at, is_active)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
        """,
        (user_id, full_name, email, hashed, matric, department, "+237600000000", role, now),
    )
    return user_id


def _upsert_course(
    conn,
    *,
    course_code: str,
    course_name: str,
    lecturer_id: str,
    lecturer_display_name: str,
    semester: str,
    academic_year: int,
    course_rep_id: str | None,
) -> str:
    existing = conn.execute(
        "SELECT id FROM courses WHERE upper(course_code) = ?",
        (course_code.upper(),),
    ).fetchone()

    if existing:
        course_id = existing["id"]
        conn.execute(
            """
            UPDATE courses
            SET course_name = ?,
                lecturer_id = ?,
                lecturer_display_name = ?,
                course_rep_id = ?,
                semester = ?,
                academic_year = ?
            WHERE id = ?
            """,
            (
                course_name,
                lecturer_id,
                lecturer_display_name,
                course_rep_id,
                semester,
                academic_year,
                course_id,
            ),
        )
        return course_id

    course_id = f"c_seed_{_slug(course_code)}"
    conn.execute(
        """
        INSERT INTO courses
        (id, course_code, course_name, lecturer_id, lecturer_display_name, course_rep_id, semester, academic_year)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            course_id,
            course_code.upper(),
            course_name,
            lecturer_id,
            lecturer_display_name,
            course_rep_id,
            semester,
            academic_year,
        ),
    )
    return course_id


def main() -> None:
    with get_conn() as conn:
        # Core roles requested by stakeholder.
        admin_id = _upsert_user(
            conn,
            user_id="u_admin_seed",
            full_name="Admin UniAttend",
            email="admin@ictuniversity.edu.cm",
            matric="ADMIN2026001",
            department="ICT",
            role="admin",
        )

        moune_id = _upsert_user(
            conn,
            user_id="u_lecturer_moune",
            full_name="Engr Moune",
            email="engr.moune@ictuniversity.edu.cm",
            matric="LECT2026001",
            department="Faculty",
            role="lecturer",
        )

        lecturer_map = {
            "Engr Palma": _upsert_user(
                conn,
                user_id="u_lecturer_palma",
                full_name="Engr Palma",
                email="engr.palma@ictuniversity.edu.cm",
                matric="LECT2026002",
                department="Faculty",
                role="lecturer",
            ),
            "Engr Tanwi": _upsert_user(
                conn,
                user_id="u_lecturer_tanwi",
                full_name="Engr Tanwi",
                email="engr.tanwi@ictuniversity.edu.cm",
                matric="LECT2026003",
                department="Faculty",
                role="lecturer",
            ),
            "Dr Fotsing": _upsert_user(
                conn,
                user_id="u_lecturer_fotsing",
                full_name="Dr Fotsing",
                email="dr.fotsing@ictuniversity.edu.cm",
                matric="LECT2026004",
                department="Faculty",
                role="lecturer",
            ),
            "Dr Fosso": _upsert_user(
                conn,
                user_id="u_lecturer_fosso",
                full_name="Dr Fosso",
                email="dr.fosso@ictuniversity.edu.cm",
                matric="LECT2026005",
                department="Faculty",
                role="lecturer",
            ),
            "Engr Nebasi": _upsert_user(
                conn,
                user_id="u_lecturer_nebasi",
                full_name="Engr Nebasi",
                email="engr.nebasi@ictuniversity.edu.cm",
                matric="LECT2026006",
                department="Faculty",
                role="lecturer",
            ),
            "Engr Andrew": _upsert_user(
                conn,
                user_id="u_lecturer_andrew",
                full_name="Engr Andrew",
                email="engr.andrew@ictuniversity.edu.cm",
                matric="LECT2026007",
                department="Faculty",
                role="lecturer",
            ),
            "Engr Ridley": _upsert_user(
                conn,
                user_id="u_lecturer_ridley",
                full_name="Engr Ridley",
                email="engr.ridley@ictuniversity.edu.cm",
                matric="LECT2026008",
                department="Faculty",
                role="lecturer",
            ),
            "Engr Colbert": _upsert_user(
                conn,
                user_id="u_lecturer_colbert",
                full_name="Engr Colbert",
                email="engr.colbert@ictuniversity.edu.cm",
                matric="LECT2026009",
                department="Faculty",
                role="lecturer",
            ),
            "Dr Nkandeu": _upsert_user(
                conn,
                user_id="u_lecturer_nkandeu",
                full_name="Dr Nkandeu",
                email="dr.nkandeu@ictuniversity.edu.cm",
                matric="LECT2026010",
                department="Faculty",
                role="lecturer",
            ),
            "Mme Agnang": _upsert_user(
                conn,
                user_id="u_lecturer_agnang",
                full_name="Mme Agnang",
                email="mme.agnang@ictuniversity.edu.cm",
                matric="LECT2026011",
                department="Faculty",
                role="lecturer",
            ),
            "Mme Tita": _upsert_user(
                conn,
                user_id="u_lecturer_tita",
                full_name="Mme Tita",
                email="mme.tita@ictuniversity.edu.cm",
                matric="LECT2026012",
                department="Faculty",
                role="lecturer",
            ),
            "Mr Betangacho": _upsert_user(
                conn,
                user_id="u_lecturer_betangacho",
                full_name="Mr Betangacho",
                email="mr.betangacho@ictuniversity.edu.cm",
                matric="LECT2026013",
                department="Faculty",
                role="lecturer",
            ),
            "BMS": _upsert_user(
                conn,
                user_id="u_lecturer_bms",
                full_name="BMS",
                email="bms@ictuniversity.edu.cm",
                matric="LECT2026014",
                department="Faculty",
                role="lecturer",
            ),
        }

        # Students captured from screenshots (partial visible roster).
        student_names = [
            "Nguend Arthur Johann",
            "Madonge Jeanne Lesline",
            "FANTY CHARLSON FANTY",
            "TELLA KEMBOU AURIENNATHAN",
            "MAJOETE LEKONTA MARIE MICHELLE",
            "SIMEAW WAMICN ANELLE",
            "MONTHE NJONKOU JOSLYN ORESTAN",
            "NGOTCHON YESSEMET ANDREA",
            "Youkou Yonkou Prince Eric",
            "TCHOUTOU WANDA ROSATINT",
            "NASSA MOSES KAMARA DIVINE KAMARA",
            "NJINKEH BRIAN ZFATA CHELIA ASAWA JR",
            "Swan Tegni Same Divine Elijah Tinsay-Fri",
            "YEMELE TANE LOIC",
            "Hainawan Birk Okskynyu",
            "Tientu Taieo Martin",
            "YANN AYMERICK ATSA AYSA",
            "Tchouksin Cender Joel",
            "Tebuogia Njoynoa Yvan Gilbert King",
            "Pan Abel Atar Janye Stanley Digenits",
            "BENEWET CANDY-BRIGHT UNIGOTON",
            "MAOKONG LAURA ELISEE",
            "Anciou Yade Joyce Lucie",
            "Djaka Godong Tnona Yannick",
            "Ton Sokaya Layla Kezze-Lion Nchfor",
            "Asobe Sally-Ann W/A Armynget Neason Jones",
            "TENES COURAGE AIWA",
            "TIGHA TRASURE YONG YAOLA",
            "Token Saglener Awaying Bilo",
            "NENDJO TANDAH BENEDINA ABRAHAMS",
            "NDI JENNIFER NENH BERLNAZE CLODYS AYANXI",
            "KONSHU JESSE NTANJ KIFINKA RUFATSES NICHA",
            "NGUISSA MOHAMED SAID",
            "Njukie Jenline Nani NCHONGNE MATTHEW AJAM GEMS MARIE",
            "NENDJO TANDAH BENEDINA ABRAHAMS",
        ]

        students: list[str] = []
        for index, name in enumerate(student_names, start=1):
            role = "student"
            # Two delegates for export-role checks.
            if index in {2, 14}:
                role = "course_rep"
            user_id = _upsert_user(
                conn,
                user_id=_user_id("u_std", name),
                full_name=name,
                email=_email_for_name(name),
                matric=f"ICTU2026{index:04d}",
                department="ICT",
                role=role,
            )
            students.append(user_id)

        delegate_primary = students[1]

        courses_input = [
            ("SEN3241", "Software Validation and Verification", "Engr Palma"),
            ("SEN3242", "Android Application Development", "Engr Moune"),
            ("SEN3243", "Advanced Web Development", "Engr Tanwi"),
            ("SEN3244", "Software Architecture", "Engr Palma"),
            ("ICT3211", "IT Infrastructure Management", "Dr Fosso"),
            ("ICT3212", "Advanced Database Systems", "Engr Moune"),
            ("CSC3221", "Introduction to Data Science", "Dr Fotsing"),
            ("CYS3251", "Network Computer Forensics", "Engr Nebasi"),
            ("ISN3231", "Network Management", "Engr Nebasi"),
            ("ISN3232", "CCNA2", "Engr Andrew"),
            ("REN3261", "Hydrogen and Fuel Cells", "Engr Ridley"),
            ("REN3262", "Application of Renewable Energy Software", "Engr Colbert"),
            ("REN3263", "Sustainable Energy Management and Climate Change", "Engr Ridley"),
            ("REN3264", "Power Plant Technology", "Engr Colbert"),
            ("REN3265", "Embedded Systems", "Dr Nkandeu"),
            ("BMS4238", "Project Management", "Engr Moune"),
            ("JMC2271", "Mobile Application Development for Journalists", "Dr Nkandeu"),
            ("JMC2272", "Newspaper Editing and Printing", "Mme Agnang"),
            ("JMC2273", "Radio and TV Programme Writing", "Mme Tita"),
            ("JMC2274", "Digital TV Production II", "Mr Betangacho"),
            ("JMC2275", "Digital Radio Production II", "Mr Betangacho"),
            ("JMC2276", "Music Production", "Mme Tita"),
            ("CVE2200", "Civics and Ethics", "BMS"),
        ]

        course_ids: dict[str, str] = {}
        for code, title, lecturer_name in courses_input:
            lecturer_id = moune_id if lecturer_name == "Engr Moune" else lecturer_map[lecturer_name]
            rep_id = delegate_primary if code == "SEN3242" else None
            course_id = _upsert_course(
                conn,
                course_code=code,
                course_name=title,
                lecturer_id=lecturer_id,
                lecturer_display_name=lecturer_name,
                semester="SPRING 2026",
                academic_year=2026,
                course_rep_id=rep_id,
            )
            course_ids[code] = course_id

        # Enroll all screenshot students into SEN3242 and selected additional courses.
        enroll_targets = {
            "SEN3242": students,
            "SEN3243": students[:20],
            "SEN3244": students[:16],
            "ICT3212": students[:12],
            "CSC3221": students[:24],
        }

        for course_code, user_ids in enroll_targets.items():
            course_id = course_ids[course_code]
            for user_id in user_ids:
                conn.execute(
                    """
                    INSERT INTO course_enrollments (id, course_id, student_id, created_at)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT (course_id, student_id) DO NOTHING
                    """,
                    (f"en_{uuid.uuid4().hex[:10]}", course_id, user_id, NOW.isoformat()),
                )

        # Seed closed sessions with attendance records for export and analytics demos.
        sen_course_id = course_ids["SEN3242"]
        session_ids = []
        for idx in range(1, 5):
            session_id = f"sess_seed_sen3242_{idx:02d}"
            session_ids.append(session_id)
            open_at = (NOW - timedelta(days=(20 - idx * 2))).isoformat()
            checkout_at = (NOW - timedelta(days=(20 - idx * 2), minutes=-40)).isoformat()
            conn.execute("DELETE FROM attendance_records WHERE session_id = ?", (session_id,))
            conn.execute("DELETE FROM attendance_manual_actions WHERE session_id = ?", (session_id,))
            conn.execute("DELETE FROM attendance_anomalies WHERE session_id = ?", (session_id,))
            conn.execute(
                """
                INSERT INTO attendance_sessions
                (id, course_id, class_type, scheduled_date, status, check_in_opened_at, check_out_opened_at,
                 classroom_latitude, classroom_longitude, created_by, created_at)
                VALUES (?, ?, 'normal', ?, 'closed', ?, ?, ?, ?, ?, ?)
                ON CONFLICT (id) DO UPDATE
                SET course_id = EXCLUDED.course_id,
                    scheduled_date = EXCLUDED.scheduled_date,
                    status = EXCLUDED.status,
                    check_in_opened_at = EXCLUDED.check_in_opened_at,
                    check_out_opened_at = EXCLUDED.check_out_opened_at,
                    classroom_latitude = EXCLUDED.classroom_latitude,
                    classroom_longitude = EXCLUDED.classroom_longitude,
                    created_by = EXCLUDED.created_by,
                    created_at = EXCLUDED.created_at
                """,
                (
                    session_id,
                    sen_course_id,
                    (NOW - timedelta(days=(20 - idx * 2))).date().isoformat(),
                    open_at,
                    checkout_at,
                    3.8480,
                    11.5021,
                    admin_id,
                    NOW.isoformat(),
                ),
            )

        sen_students = enroll_targets["SEN3242"]
        for sidx, student_id in enumerate(sen_students):
            for x, session_id in enumerate(session_ids, start=1):
                state = (sidx + x) % 5
                if state == 0:
                    status = "absent"
                    check_in = None
                    check_out = None
                elif state in {1, 2}:
                    status = "present"
                    check_in = (NOW - timedelta(days=(20 - x * 2), minutes=3 + (sidx % 7))).isoformat()
                    check_out = (NOW - timedelta(days=(20 - x * 2), minutes=-35 - (sidx % 4))).isoformat()
                else:
                    status = "partial"
                    check_in = (NOW - timedelta(days=(20 - x * 2), minutes=8 + (sidx % 6))).isoformat()
                    check_out = None

                conn.execute(
                    """
                    INSERT INTO attendance_records
                    (id, session_id, student_id, check_in_time, check_out_time,
                     check_in_latitude, check_in_longitude, check_out_latitude, check_out_longitude,
                     device_id, status, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT (session_id, student_id) DO UPDATE
                    SET check_in_time = EXCLUDED.check_in_time,
                        check_out_time = EXCLUDED.check_out_time,
                        check_in_latitude = EXCLUDED.check_in_latitude,
                        check_in_longitude = EXCLUDED.check_in_longitude,
                        check_out_latitude = EXCLUDED.check_out_latitude,
                        check_out_longitude = EXCLUDED.check_out_longitude,
                        device_id = EXCLUDED.device_id,
                        status = EXCLUDED.status,
                        updated_at = EXCLUDED.updated_at
                    """,
                    (
                        f"att_{uuid.uuid4().hex[:10]}",
                        session_id,
                        student_id,
                        check_in,
                        check_out,
                        3.8480,
                        11.5021,
                        3.8481,
                        11.5020,
                        f"seed-device-{sidx:03d}",
                        status,
                        NOW.isoformat(),
                        NOW.isoformat(),
                    ),
                )

        conn.commit()

    print("Seed completed successfully.")
    print(f"Default password for all seeded users: {DEFAULT_PASSWORD}")
    print("Seeded course focus: SEN3242 - Android Application Development (Engr Moune)")


if __name__ == "__main__":
    main()

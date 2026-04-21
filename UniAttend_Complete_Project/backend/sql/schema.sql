PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  matric_number TEXT NOT NULL UNIQUE,
  department TEXT NOT NULL,
  phone_number TEXT,
  role TEXT NOT NULL CHECK (role IN ('student', 'course_rep', 'lecturer', 'admin', 'super_admin')),
  created_at TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  blocked_at TEXT,
  blocked_reason TEXT
);

CREATE TABLE IF NOT EXISTS role_applications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  requested_role TEXT NOT NULL CHECK (requested_role IN ('course_rep', 'lecturer', 'admin')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
  justification TEXT,
  reviewed_by TEXT,
  reviewed_at TEXT,
  created_at TEXT NOT NULL,
  UNIQUE (user_id, requested_role, status),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS courses (
  id TEXT PRIMARY KEY,
  course_code TEXT NOT NULL UNIQUE,
  course_name TEXT NOT NULL,
  lecturer_id TEXT NOT NULL,
  lecturer_display_name TEXT,
  course_rep_id TEXT,
  semester TEXT NOT NULL,
  academic_year INTEGER NOT NULL,
  FOREIGN KEY (lecturer_id) REFERENCES users(id),
  FOREIGN KEY (course_rep_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS course_enrollments (
  id TEXT PRIMARY KEY,
  course_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE (course_id, student_id),
  FOREIGN KEY (course_id) REFERENCES courses(id),
  FOREIGN KEY (student_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS attendance_sessions (
  id TEXT PRIMARY KEY,
  course_id TEXT NOT NULL,
  class_type TEXT NOT NULL CHECK (class_type IN ('normal', 'catch_up')),
  scheduled_date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'open_for_check_in', 'open_for_check_out', 'closed')),
  check_in_opened_at TEXT,
  check_out_opened_at TEXT,
  classroom_latitude REAL,
  classroom_longitude REAL,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (course_id) REFERENCES courses(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS device_bindings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE (user_id),
  UNIQUE (device_id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS attendance_records (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  check_in_time TEXT,
  check_out_time TEXT,
  check_in_latitude REAL,
  check_in_longitude REAL,
  check_out_latitude REAL,
  check_out_longitude REAL,
  device_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('absent', 'partial', 'present')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (session_id, student_id),
  FOREIGN KEY (session_id) REFERENCES attendance_sessions(id),
  FOREIGN KEY (student_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS attendance_manual_actions (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  added_by TEXT NOT NULL,
  reason TEXT,
  created_at TEXT NOT NULL,
  UNIQUE (session_id, student_id),
  FOREIGN KEY (session_id) REFERENCES attendance_sessions(id),
  FOREIGN KEY (student_id) REFERENCES users(id),
  FOREIGN KEY (added_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS attendance_anomalies (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  student_id TEXT NOT NULL,
  flagged_by TEXT NOT NULL,
  reason TEXT NOT NULL,
  details TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES attendance_sessions(id),
  FOREIGN KEY (student_id) REFERENCES users(id),
  FOREIGN KEY (flagged_by) REFERENCES users(id)
);

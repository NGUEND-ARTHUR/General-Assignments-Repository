const { test, expect } = require('@playwright/test');

async function apiCall(request, method, path, token, data) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  const res = await request.fetch(path, {
    method,
    headers,
    data,
  });

  let body = null;
  try {
    body = await res.json();
  } catch {
    body = null;
  }

  return { status: res.status(), ok: res.ok(), body };
}

async function login(request, email, password) {
  const result = await apiCall(request, 'POST', '/auth/login', null, {
    email,
    password,
  });

  expect(result.status, `login failed for ${email}`).toBe(200);
  expect(result.body?.access_token).toBeTruthy();
  expect(result.body?.user?.id).toBeTruthy();

  return {
    token: result.body.access_token,
    user: result.body.user,
  };
}

async function firstManageableCourseId(request, token) {
  const courses = await apiCall(request, 'GET', '/courses', token);
  expect(courses.status).toBe(200);
  const list = Array.isArray(courses.body?.courses) ? courses.body.courses : [];
  const manageable = list.find((c) => c?.can_manage === true);
  return manageable ? manageable.id : null;
}

async function createSession(request, token, courseId) {
  return apiCall(request, 'POST', '/sessions', token, {
    course_id: courseId,
    class_type: 'normal',
    scheduled_date: new Date().toISOString(),
    classroom_latitude: 3.848,
    classroom_longitude: 11.502,
  });
}

test.describe('Role Matrix MVP - Complete functional verification', () => {
  test('all roles enforce and expose expected capabilities', async ({ request }) => {
    const health = await apiCall(request, 'GET', '/health');
    expect(health.status).toBe(200);
    expect(health.body?.ok).toBe(true);

    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');
    const rep = await login(request, 'rep@ictuniversity.edu.cm', 'Rep@1234');
    const lecturer = await login(request, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');
    const admin = await login(request, 'admin@ictuniversity.edu.cm', 'Admin@1234');
    const superAdmin = await login(
      request,
      'nguend.johann@ictuniversity.edu.cm',
      'Arthutr@ictu2024',
    );

    // Student capabilities and restrictions.
    const studentCourses = await apiCall(request, 'GET', '/courses', student.token);
    expect(studentCourses.status).toBe(200);
    expect((studentCourses.body?.courses || []).length).toBeGreaterThan(0);
    expect((studentCourses.body?.courses || []).every((course) => course?.can_manage !== true)).toBeTruthy();

    const studentAttendanceMe = await apiCall(request, 'GET', '/attendance/me', student.token);
    expect(studentAttendanceMe.status).toBe(200);

    const studentCourseId = (studentCourses.body?.courses || [])[0]?.id;
    if (studentCourseId) {
      const studentCreateSession = await createSession(request, student.token, studentCourseId);
      expect(studentCreateSession.status).toBe(403);
    }

    const studentRoleApprovals = await apiCall(
      request,
      'GET',
      '/admin/role-applications',
      student.token,
    );
    expect(studentRoleApprovals.status).toBe(403);

    // Course rep capabilities.
    const repCourseId = await firstManageableCourseId(request, rep.token);
    expect(repCourseId, 'course rep should have at least one manageable course').toBeTruthy();
    expect(
      (await apiCall(request, 'GET', '/courses', rep.token)).body.courses.every((course) => course?.course_rep_id === rep.user.id || course?.can_manage !== true),
    ).toBeTruthy();

    const repCreateSession = await createSession(request, rep.token, repCourseId);
    expect(repCreateSession.status).toBe(200);
    const repSessionId = repCreateSession.body?.session?.id;
    expect(repSessionId).toBeTruthy();

    const repCloseSession = await apiCall(
      request,
      'POST',
      `/sessions/${repSessionId}/close`,
      rep.token,
    );
    expect(repCloseSession.status).toBe(200);

    const repUpdateSession = await apiCall(
      request,
      'PUT',
      `/sessions/${repSessionId}`,
      rep.token,
      {
        course_id: repCourseId,
        class_type: 'normal',
        scheduled_date: new Date(Date.now() + 60_000).toISOString(),
        classroom_latitude: 3.849,
        classroom_longitude: 11.503,
      },
    );
    expect(repUpdateSession.status).toBe(200);

    // Lecturer capabilities.
    const lecturerCourseId = await firstManageableCourseId(request, lecturer.token);
    expect(lecturerCourseId, 'lecturer should have at least one manageable course').toBeTruthy();
    expect(
      (await apiCall(request, 'GET', '/courses', lecturer.token)).body.courses.every((course) => course?.lecturer_id === lecturer.user.id),
    ).toBeTruthy();

    const lecturerCreateSession = await createSession(request, lecturer.token, lecturerCourseId);
    expect(lecturerCreateSession.status).toBe(200);

    const lecturerCreateCourse = await apiCall(request, 'POST', '/courses', lecturer.token, {
      course_code: `LCT${Date.now().toString().slice(-6)}`,
      course_name: 'Lecturer Created Course',
      semester: 'Semester 1',
      academic_year: 2026,
    });
    expect(lecturerCreateCourse.status).toBe(200);

    // Admin capabilities.
    const adminCourseId = await firstManageableCourseId(request, admin.token);
    expect(adminCourseId, 'admin should have at least one manageable course').toBeTruthy();

    const adminCreateSession = await createSession(request, admin.token, adminCourseId);
    expect(adminCreateSession.status).toBe(200);

    const adminCreateCourseMissingLecturer = await apiCall(
      request,
      'POST',
      '/courses',
      admin.token,
      {
        course_code: `ADM${Date.now().toString().slice(-6)}`,
        course_name: 'Admin Missing Lecturer',
        semester: 'Semester 1',
        academic_year: 2026,
      },
    );
    expect(adminCreateCourseMissingLecturer.status).toBe(400);

    const adminCreateCourseBadLecturer = await apiCall(
      request,
      'POST',
      '/courses',
      admin.token,
      {
        course_code: `ADB${Date.now().toString().slice(-6)}`,
        course_name: 'Admin Bad Lecturer',
        semester: 'Semester 1',
        academic_year: 2026,
        lecturer_id: 'u_student_default',
      },
    );
    expect(adminCreateCourseBadLecturer.status).toBe(400);

    const adminCreateCourseGoodLecturer = await apiCall(
      request,
      'POST',
      '/courses',
      admin.token,
      {
        course_code: `ADG${Date.now().toString().slice(-6)}`,
        course_name: 'Admin Good Lecturer',
        semester: 'Semester 1',
        academic_year: 2026,
        lecturer_identifier: 'lecturer@ictuniversity.edu.cm',
      },
    );
    expect(adminCreateCourseGoodLecturer.status).toBe(200);

    const dashboard = await apiCall(request, 'GET', '/analytics/dashboard', student.token);
    expect(dashboard.status).toBe(200);
    expect(Array.isArray(dashboard.body?.courses)).toBeTruthy();

    // Super admin capabilities and privileged actions.
    const superRoleApprovals = await apiCall(
      request,
      'GET',
      '/admin/role-applications',
      superAdmin.token,
    );
    expect(superRoleApprovals.status).toBe(200);

    const lecturerSessionId = lecturerCreateSession.body?.session?.id;
    expect(lecturerSessionId).toBeTruthy();

    const adminManualAdd = await apiCall(request, 'POST', '/attendance/manual-add', admin.token, {
      session_id: lecturerSessionId,
      student_identifier: 'STUDENT001',
      reason: 'admin-should-fail',
    });
    expect(adminManualAdd.status).toBe(403);

    const superManualAdd = await apiCall(
      request,
      'POST',
      '/attendance/manual-add',
      superAdmin.token,
      {
        session_id: lecturerSessionId,
        student_identifier: 'STUDENT001',
        reason: 'super-admin-role-matrix',
      },
    );
    expect(superManualAdd.status).toBe(200);
  });
});

const { test, expect } = require('@playwright/test');
const {
  uniqueEmail,
  login,
  register,
  authGet,
  authPost,
  authPut,
  authDelete,
} = require('./helpers/api');

test.describe('API endpoint health and contract checks', () => {
  test('health endpoint responds and service is up', async ({ request }) => {
    const response = await request.get('/health');
    expect(response.ok()).toBeTruthy();

    const body = await response.json();
    expect(body.ok).toBe(true);
    expect(body.service).toBe('uniattend-backend');
  });

  test('auth register, login, and me endpoints work', async ({ request }) => {
    const email = uniqueEmail('mvp_student');
    const catalogResponse = await request.get('/courses/catalog');
    expect(catalogResponse.ok()).toBeTruthy();
    const catalogBody = await catalogResponse.json();
    expect(Array.isArray(catalogBody.courses)).toBeTruthy();

    const selectedCourseIds = (catalogBody.courses || []).slice(0, 2).map((course) => course.id);
    const registration = await register(request, {
      full_name: 'Playwright MVP Student',
      email,
      password: 'Student@1234',
      matric_number: `PW${Date.now()}`,
      department: 'SEN',
      phone_number: '+237600000000',
      role: 'student',
      selected_course_ids: selectedCourseIds,
    });

    expect(registration.token).toBeTruthy();
    expect(registration.user.email).toBe(email);

    const loggedIn = await login(request, email, 'Student@1234');
    expect(loggedIn.user.id).toBe(registration.user.id);

    const meResponse = await authGet(request, '/auth/me', loggedIn.token);
    expect(meResponse.ok()).toBeTruthy();
    const me = await meResponse.json();
    expect(me.user.email).toBe(email);

    const myCoursesResponse = await authGet(request, '/me/courses', loggedIn.token);
    expect(myCoursesResponse.ok()).toBeTruthy();
    const myCourses = (await myCoursesResponse.json()).courses;
    expect(myCourses.length).toBe(selectedCourseIds.length);
  });

  test('courses, sessions, and attendance endpoints function as expected', async ({ request }) => {
    const lecturer = await login(request, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');
    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');

    const coursesResponse = await authGet(request, '/courses', lecturer.token);
    expect(coursesResponse.ok()).toBeTruthy();
    const coursesPayload = await coursesResponse.json();
    expect(Array.isArray(coursesPayload.courses)).toBeTruthy();
    expect(coursesPayload.courses.length).toBeGreaterThan(0);

    const courseId = coursesPayload.courses[0].id;

    const enrollResponse = await authPost(request, `/me/courses/${courseId}`, student.token);
    expect(enrollResponse.ok()).toBeTruthy();

    const createSessionResponse = await authPost(request, '/sessions', lecturer.token, {
      course_id: courseId,
      class_type: 'normal',
      scheduled_date: new Date().toISOString(),
      classroom_latitude: 3.8667,
      classroom_longitude: 11.5167,
    });
    expect(createSessionResponse.ok()).toBeTruthy();
    const createdSession = (await createSessionResponse.json()).session;
    expect(createdSession.id).toBeTruthy();

    const sessionId = createdSession.id;

    const sessionDetailResponse = await authGet(request, `/sessions/${sessionId}`, lecturer.token);
    expect(sessionDetailResponse.ok()).toBeTruthy();
    const sessionDetail = (await sessionDetailResponse.json()).session;
    expect(sessionDetail.id).toBe(sessionId);

    const courseSessionsResponse = await authGet(request, `/sessions/course/${courseId}`, lecturer.token);
    expect(courseSessionsResponse.ok()).toBeTruthy();
    const courseSessions = (await courseSessionsResponse.json()).sessions;
    expect(courseSessions.some((s) => s.id === sessionId)).toBeTruthy();

    const activeSessionResponse = await authGet(request, `/sessions/active/${courseId}`, lecturer.token);
    expect(activeSessionResponse.ok()).toBeTruthy();
    const activeSession = (await activeSessionResponse.json()).session;
    expect(activeSession).toBeTruthy();

    const updateSessionResponse = await authPut(request, `/sessions/${sessionId}`, lecturer.token, {
      course_id: courseId,
      class_type: 'catch_up',
      scheduled_date: new Date(Date.now() + 60_000).toISOString(),
      classroom_latitude: 3.9,
      classroom_longitude: 11.5,
    });
    expect(updateSessionResponse.ok()).toBeTruthy();
    const updated = (await updateSessionResponse.json()).session;
    expect(updated.class_type).toBe('catch_up');

    const studentCreateSessionResponse = await authPost(request, '/sessions', student.token, {
      course_id: courseId,
      class_type: 'normal',
      scheduled_date: new Date().toISOString(),
      classroom_latitude: 3.8,
      classroom_longitude: 11.4,
    });
    expect(studentCreateSessionResponse.status()).toBe(403);

    const checkInResponse = await authPost(request, '/attendance/checkin', student.token, {
      session_id: sessionId,
      student_id: student.user.id,
      device_id: 'pw-device-001',
      latitude: 3.9,
      longitude: 11.5,
    });
    expect(checkInResponse.ok()).toBeTruthy();
    const checkInPayload = await checkInResponse.json();
    expect(checkInPayload.status).toBe('partial');

    const duplicateCheckIn = await authPost(request, '/attendance/checkin', student.token, {
      session_id: sessionId,
      student_id: student.user.id,
      device_id: 'pw-device-001',
      latitude: 3.8667,
      longitude: 11.5167,
    });
    expect(duplicateCheckIn.status()).toBe(409);

    const checkOutResponse = await authPost(request, '/attendance/checkout', student.token, {
      session_id: sessionId,
      student_id: student.user.id,
      device_id: 'pw-device-001',
      latitude: 3.9,
      longitude: 11.5,
    });
    expect(checkOutResponse.ok()).toBeTruthy();
    const checkOutPayload = await checkOutResponse.json();
    expect(checkOutPayload.status).toBe('present');

    const duplicateCheckOut = await authPost(request, '/attendance/checkout', student.token, {
      session_id: sessionId,
      student_id: student.user.id,
      device_id: 'pw-device-001',
      latitude: 3.9,
      longitude: 11.5,
    });
    expect(duplicateCheckOut.status()).toBe(409);

    const attendanceSessionResponse = await authGet(
      request,
      `/attendance/session/${sessionId}`,
      lecturer.token,
    );
    expect(attendanceSessionResponse.ok()).toBeTruthy();
    const attendanceSession = (await attendanceSessionResponse.json()).records;
    expect(attendanceSession.some((record) => record.student_id === student.user.id)).toBeTruthy();

    const myAttendanceResponse = await authGet(request, '/attendance/me', student.token);
    expect(myAttendanceResponse.ok()).toBeTruthy();
    const myAttendance = (await myAttendanceResponse.json()).records;
    expect(myAttendance.some((record) => record.session_id === sessionId)).toBeTruthy();

    const dashboardResponse = await authGet(request, '/analytics/dashboard', lecturer.token);
    expect(dashboardResponse.ok()).toBeTruthy();
    const dashboard = await dashboardResponse.json();
    expect(Array.isArray(dashboard.courses)).toBeTruthy();

    const unenrollResponse = await authDelete(request, `/me/courses/${courseId}`, student.token);
    expect(unenrollResponse.ok()).toBeTruthy();
  });
});

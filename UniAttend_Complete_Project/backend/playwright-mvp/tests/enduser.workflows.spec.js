const { test, expect } = require('@playwright/test');
const { login, register, authGet, authPost } = require('./helpers/api');

test.describe('End-user workflow MVP checks', () => {
  test('lecturer creates a session, student attends, admin audits records', async ({ request }) => {
    const lecturer = await login(request, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');
    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');

    const coursesResponse = await authGet(request, '/courses', lecturer.token);
    expect(coursesResponse.ok()).toBeTruthy();
    const course = (await coursesResponse.json()).courses[0];
    expect(course).toBeTruthy();

    const createSessionResponse = await authPost(request, '/sessions', lecturer.token, {
      course_id: course.id,
      class_type: 'normal',
      scheduled_date: new Date().toISOString(),
      classroom_latitude: 3.8667,
      classroom_longitude: 11.5167,
    });
    expect(createSessionResponse.ok()).toBeTruthy();
    const createdSession = (await createSessionResponse.json()).session;

    const enrollStudentResponse = await authPost(request, `/me/courses/${course.id}`, student.token);
    expect(enrollStudentResponse.ok()).toBeTruthy();

    const studentCoursesResponse = await authGet(request, '/courses', student.token);
    expect(studentCoursesResponse.ok()).toBeTruthy();
    const studentCourses = (await studentCoursesResponse.json()).courses;
    expect(studentCourses.some((c) => c.id === course.id)).toBeTruthy();

    const checkInResponse = await authPost(request, '/attendance/checkin', student.token, {
      session_id: createdSession.id,
      student_id: student.user.id,
      device_id: `device-${Date.now()}`,
      latitude: 3.8667,
      longitude: 11.5167,
    });
    expect(checkInResponse.ok()).toBeTruthy();

    const checkOutResponse = await authPost(request, '/attendance/checkout', student.token, {
      session_id: createdSession.id,
      student_id: student.user.id,
      device_id: `device-${Date.now()}`,
      latitude: 3.8667,
      longitude: 11.5167,
    });
    expect(checkOutResponse.ok()).toBeTruthy();

    const studentHistoryResponse = await authGet(request, '/attendance/me', student.token);
    expect(studentHistoryResponse.ok()).toBeTruthy();
    const history = (await studentHistoryResponse.json()).records;
    const attended = history.find((r) => r.session_id === createdSession.id);
    expect(attended).toBeTruthy();
    expect(attended.status).toBe('present');

    const admin = await login(request, 'admin@ictuniversity.edu.cm', 'Admin@1234');

    const sessionRecordsResponse = await authGet(
      request,
      `/attendance/session/${createdSession.id}`,
      admin.token,
    );
    expect(sessionRecordsResponse.ok()).toBeTruthy();
    const records = (await sessionRecordsResponse.json()).records;
    const row = records.find((r) => r.student_id === student.user.id);
    expect(row).toBeTruthy();
    expect(row.status).toBe('present');
  });
});

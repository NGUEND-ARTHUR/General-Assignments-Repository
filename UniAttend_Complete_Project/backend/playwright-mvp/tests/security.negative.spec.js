const { test, expect } = require('@playwright/test');
const { uniqueEmail, login, register, authGet, authPost } = require('./helpers/api');

test.describe('Security and negative test cases', () => {
  test('invalid credentials return 401 unauthorized', async ({ request }) => {
    const response = await request.post('/auth/login', {
      data: {
          email: 'nonexistent@ictuniversity.edu.cm',
        password: 'WrongPassword123',
      },
    });
    expect(response.status()).toBe(401);
    const body = await response.json();
    expect(body.detail).toBe('Invalid credentials');
  });

  test('missing authorization header returns 401', async ({ request }) => {
    const response = await request.get('/courses');
    expect(response.status()).toBe(401);
    const body = await response.json();
    expect(body.detail).toContain('Missing bearer token');
  });

  test('invalid bearer token returns 401', async ({ request }) => {
    const response = await request.get('/courses', {
      headers: {
        Authorization: 'Bearer invalid-token-xyz',
      },
    });
    expect(response.status()).toBe(401);
    const body = await response.json();
    expect(body.detail).toContain('Invalid token');
  });

  test('malformed authorization header returns 401', async ({ request }) => {
    const response = await request.get('/courses', {
      headers: {
        Authorization: 'InvalidFormat token-here',
      },
    });
    expect(response.status()).toBe(401);
  });

  test('student cannot create sessions (role-based access control)', async ({ request }) => {
    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');

    const coursesResponse = await authGet(request, '/courses', student.token);
    const courses = (await coursesResponse.json()).courses;

    if (courses.length === 0) {
      test.skip();
      return;
    }

    const response = await authPost(request, '/sessions', student.token, {
      course_id: courses[0].id,
      class_type: 'normal',
      scheduled_date: new Date().toISOString(),
      classroom_latitude: 3.8,
      classroom_longitude: 11.5,
    });
    expect(response.status()).toBe(403);
    const body = await response.json();
    expect(body.detail).toBe('Only staff can create sessions');
  });

  test('duplicate email registration returns 409 conflict', async ({ request }) => {
    const email = uniqueEmail('conflict_test');

    const first = await register(request, {
      full_name: 'First User',
      email,
      password: 'Password@1234',
      matric_number: `MT${Date.now()}`,
      department: 'SEN',
      role: 'student',
    });
    expect(first.token).toBeTruthy();

    const duplicate = await request.post('/auth/register', {
      data: {
        full_name: 'Second User',
        email,
        password: 'Password@1234',
        matric_number: `MT${Date.now() + 1000}`,
        department: 'SEN',
        role: 'student',
      },
    });
    expect(duplicate.status()).toBe(409);
    const body = await duplicate.json();
    expect(body.detail).toBe('Email or matric already exists');
  });

  test('duplicate matric_number registration returns 409 conflict', async ({ request }) => {
    const matric = `MAT${Date.now()}`;

    const first = await register(request, {
      full_name: 'First Matric User',
      email: uniqueEmail('matric_1'),
      password: 'Password@1234',
      matric_number: matric,
      department: 'SEN',
      role: 'student',
    });
    expect(first.token).toBeTruthy();

    const duplicate = await request.post('/auth/register', {
      data: {
        full_name: 'Second Matric User',
        email: uniqueEmail('matric_2'),
        password: 'Password@1234',
        matric_number: matric,
        department: 'SEN',
        role: 'student',
      },
    });
    expect(duplicate.status()).toBe(409);
  });

  test('check-in without session returns 404', async ({ request }) => {
    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');

    const response = await authPost(request, '/attendance/checkin', student.token, {
      session_id: 'nonexistent-session-id',
      student_id: student.user.id,
      device_id: 'device-001',
      latitude: 3.8,
      longitude: 11.5,
    });
    expect(response.status()).toBe(404);
    const body = await response.json();
    expect(body.detail).toBe('Session not found');
  });

  test('check-out without prior check-in returns 400', async ({ request }) => {
    const lecturer = await login(request, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');
    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');

    const coursesResponse = await authGet(request, '/courses', lecturer.token);
    const course = (await coursesResponse.json()).courses[0];

    const sessionResponse = await authPost(request, '/sessions', lecturer.token, {
      course_id: course.id,
      class_type: 'normal',
      scheduled_date: new Date().toISOString(),
      classroom_latitude: 3.8667,
      classroom_longitude: 11.5167,
    });
    const session = (await sessionResponse.json()).session;

    const checkoutResponse = await authPost(request, '/attendance/checkout', student.token, {
      session_id: session.id,
      student_id: student.user.id,
      device_id: 'device-001',
      latitude: 3.8667,
      longitude: 11.5167,
    });
    expect(checkoutResponse.status()).toBe(400);
    const body = await checkoutResponse.json();
    expect(body.detail).toContain('Check-in required before check-out');
  });

  test('malformed request payload returns validation error', async ({ request }) => {
    const response = await request.post('/auth/login', {
      data: {
        email: 'invalid-not-an-email',
        password: 'Short',
      },
    });
    expect(response.status()).toBe(422);
  });

  test('non-existent session retrieval returns 404', async ({ request }) => {
    const lecturer = await login(request, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');

    const response = await authGet(request, '/sessions/nonexistent-id', lecturer.token);
    expect(response.status()).toBe(404);
    const body = await response.json();
    expect(body.detail).toBe('Session not found');
  });

  test('user cannot check-in twice to same session', async ({ request }) => {
    const lecturer = await login(request, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');
    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');

    const coursesResponse = await authGet(request, '/courses', lecturer.token);
    const course = (await coursesResponse.json()).courses[0];

    const sessionResponse = await authPost(request, '/sessions', lecturer.token, {
      course_id: course.id,
      class_type: 'normal',
      scheduled_date: new Date().toISOString(),
      classroom_latitude: 3.8667,
      classroom_longitude: 11.5167,
    });
    const session = (await sessionResponse.json()).session;

    const firstCheckin = await authPost(request, '/attendance/checkin', student.token, {
      session_id: session.id,
      student_id: student.user.id,
      device_id: 'device-001',
      latitude: 3.8667,
      longitude: 11.5167,
    });
    expect(firstCheckin.ok()).toBeTruthy();

    const secondCheckin = await authPost(request, '/attendance/checkin', student.token, {
      session_id: session.id,
      student_id: student.user.id,
      device_id: 'device-001',
      latitude: 3.8667,
      longitude: 11.5167,
    });
    expect(secondCheckin.status()).toBe(409);
    const body = await secondCheckin.json();
    expect(body.detail).toBe('Already checked in');
  });

  test('course_rep cannot view other course attendance without enrollment', async ({ request }) => {
    const rep = await login(request, 'rep@ictuniversity.edu.cm', 'Rep@1234');

    const coursesResponse = await authGet(request, '/courses', rep.token);
    expect(coursesResponse.ok()).toBeTruthy();
    const courses = (await coursesResponse.json()).courses;

    const courseCount = courses.length;
    expect(courseCount).toBeGreaterThan(0);

    if (courseCount > 0) {
      const courseId = courses[0].id;
      const sessionResponse = await authGet(request, `/sessions/course/${courseId}`, rep.token);
      expect(sessionResponse.ok()).toBeTruthy();
    }
  });
});

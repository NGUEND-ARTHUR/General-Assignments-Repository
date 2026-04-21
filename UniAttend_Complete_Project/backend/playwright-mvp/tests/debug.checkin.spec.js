const { test, expect } = require('@playwright/test');
const { login, authPost, authGet } = require('./helpers/api');

test.describe('Debug: Check-in endpoint issues', () => {
  test('diagnose check-in failure', async ({ request }) => {
    const lecturer = await login(request, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');
    const student = await login(request, 'student@ictuniversity.edu.cm', 'Student@1234');

    console.log('\n=== Student ID:', student.user.id);
    console.log('=== Lecturer ID:', lecturer.user.id);

    // Get lecturer's courses
    const coursesResponse = await authGet(request, '/courses', lecturer.token);
    console.log('\n=== GET /courses (lecturer) status:', coursesResponse.status());
    const coursesPayload = await coursesResponse.json();
    const courseId = coursesPayload.courses[0].id;
    console.log('=== Selected course:', courseId);

    // Enroll student
    const enrollResponse = await authPost(request, `/me/courses/${courseId}`, student.token);
    console.log('\n=== POST /me/courses/{id} (enroll) status:', enrollResponse.status());
    if (!enrollResponse.ok()) {
      const enrollBody = await enrollResponse.text();
      console.log('=== Enroll error:', enrollBody);
    }

    // Create session
    const createSessionResponse = await authPost(request, '/sessions', lecturer.token, {
      course_id: courseId,
      class_type: 'normal',
      scheduled_date: new Date().toISOString(),
      classroom_latitude: 3.8667,
      classroom_longitude: 11.5167,
    });
    console.log('\n=== POST /sessions status:', createSessionResponse.status());
    const createdSession = (await createSessionResponse.json()).session;
    const sessionId = createdSession.id;
    console.log('=== Created session:', sessionId, 'Status:', createdSession.status);

    // Attempt check-in
    console.log('\n=== Attempting check-in...');
    const checkInRequest = {
      session_id: sessionId,
      student_id: student.user.id,
      device_id: 'debug-device-001',
      latitude: 3.8667,
      longitude: 11.5167,
    };
    console.log('=== Check-in request body:', JSON.stringify(checkInRequest, null, 2));
    
    const checkInResponse = await authPost(request, '/attendance/checkin', student.token, checkInRequest);
    console.log('\n=== POST /attendance/checkin status:', checkInResponse.status());
    console.log('=== Check-in response.ok():', checkInResponse.ok());
    
    const checkInBody = await checkInResponse.text();
    console.log('=== Check-in response body:', checkInBody);

    if (!checkInResponse.ok()) {
      try {
        const checkInJson = JSON.parse(checkInBody);
        console.log('=== Check-in error detail:', checkInJson.detail || checkInJson);
      } catch (e) {
        console.log('=== Could not parse response as JSON');
      }
    }

    expect(checkInResponse.ok()).toBeTruthy();
  });
});

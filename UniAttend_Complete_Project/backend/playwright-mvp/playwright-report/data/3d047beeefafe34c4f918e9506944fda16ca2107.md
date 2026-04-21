# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: role.matrix.mvp.spec.js >> Role Matrix MVP - Complete functional verification >> all roles enforce and expose expected capabilities
- Location: tests\role.matrix.mvp.spec.js:56:3

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: 400
Received: 200
```

# Test source

```ts
  66  |       request,
  67  |       'nguend.johann@ictuniversity.edu.cm',
  68  |       'Arthutr@ictu2024',
  69  |     );
  70  | 
  71  |     // Student capabilities and restrictions.
  72  |     const studentCourses = await apiCall(request, 'GET', '/courses', student.token);
  73  |     expect(studentCourses.status).toBe(200);
  74  |     expect((studentCourses.body?.courses || []).length).toBeGreaterThan(0);
  75  |     expect((studentCourses.body?.courses || []).every((course) => course?.can_manage !== true)).toBeTruthy();
  76  | 
  77  |     const studentAttendanceMe = await apiCall(request, 'GET', '/attendance/me', student.token);
  78  |     expect(studentAttendanceMe.status).toBe(200);
  79  | 
  80  |     const studentCourseId = (studentCourses.body?.courses || [])[0]?.id;
  81  |     if (studentCourseId) {
  82  |       const studentCreateSession = await createSession(request, student.token, studentCourseId);
  83  |       expect(studentCreateSession.status).toBe(403);
  84  |     }
  85  | 
  86  |     const studentRoleApprovals = await apiCall(
  87  |       request,
  88  |       'GET',
  89  |       '/admin/role-applications',
  90  |       student.token,
  91  |     );
  92  |     expect(studentRoleApprovals.status).toBe(403);
  93  | 
  94  |     // Course rep capabilities.
  95  |     const repCourseId = await firstManageableCourseId(request, rep.token);
  96  |     expect(repCourseId, 'course rep should have at least one manageable course').toBeTruthy();
  97  |     expect(
  98  |       (await apiCall(request, 'GET', '/courses', rep.token)).body.courses.every((course) => course?.course_rep_id === rep.user.id || course?.can_manage !== true),
  99  |     ).toBeTruthy();
  100 | 
  101 |     const repCreateSession = await createSession(request, rep.token, repCourseId);
  102 |     expect(repCreateSession.status).toBe(200);
  103 |     const repSessionId = repCreateSession.body?.session?.id;
  104 |     expect(repSessionId).toBeTruthy();
  105 | 
  106 |     const repCloseSession = await apiCall(
  107 |       request,
  108 |       'POST',
  109 |       `/sessions/${repSessionId}/close`,
  110 |       rep.token,
  111 |     );
  112 |     expect(repCloseSession.status).toBe(200);
  113 | 
  114 |     const repUpdateSession = await apiCall(
  115 |       request,
  116 |       'PUT',
  117 |       `/sessions/${repSessionId}`,
  118 |       rep.token,
  119 |       {
  120 |         course_id: repCourseId,
  121 |         class_type: 'normal',
  122 |         scheduled_date: new Date(Date.now() + 60_000).toISOString(),
  123 |         classroom_latitude: 3.849,
  124 |         classroom_longitude: 11.503,
  125 |       },
  126 |     );
  127 |     expect(repUpdateSession.status).toBe(200);
  128 | 
  129 |     // Lecturer capabilities.
  130 |     const lecturerCourseId = await firstManageableCourseId(request, lecturer.token);
  131 |     expect(lecturerCourseId, 'lecturer should have at least one manageable course').toBeTruthy();
  132 |     expect(
  133 |       (await apiCall(request, 'GET', '/courses', lecturer.token)).body.courses.every((course) => course?.lecturer_id === lecturer.user.id),
  134 |     ).toBeTruthy();
  135 | 
  136 |     const lecturerCreateSession = await createSession(request, lecturer.token, lecturerCourseId);
  137 |     expect(lecturerCreateSession.status).toBe(200);
  138 | 
  139 |     const lecturerCreateCourse = await apiCall(request, 'POST', '/courses', lecturer.token, {
  140 |       course_code: `LCT${Date.now().toString().slice(-6)}`,
  141 |       course_name: 'Lecturer Created Course',
  142 |       semester: 'Semester 1',
  143 |       academic_year: 2026,
  144 |     });
  145 |     expect(lecturerCreateCourse.status).toBe(200);
  146 | 
  147 |     // Admin capabilities.
  148 |     const adminCourseId = await firstManageableCourseId(request, admin.token);
  149 |     expect(adminCourseId, 'admin should have at least one manageable course').toBeTruthy();
  150 | 
  151 |     const adminCreateSession = await createSession(request, admin.token, adminCourseId);
  152 |     expect(adminCreateSession.status).toBe(200);
  153 | 
  154 |     const adminCreateCourseMissingLecturer = await apiCall(
  155 |       request,
  156 |       'POST',
  157 |       '/courses',
  158 |       admin.token,
  159 |       {
  160 |         course_code: `ADM${Date.now().toString().slice(-6)}`,
  161 |         course_name: 'Admin Missing Lecturer',
  162 |         semester: 'Semester 1',
  163 |         academic_year: 2026,
  164 |       },
  165 |     );
> 166 |     expect(adminCreateCourseMissingLecturer.status).toBe(400);
      |                                                     ^ Error: expect(received).toBe(expected) // Object.is equality
  167 | 
  168 |     const adminCreateCourseBadLecturer = await apiCall(
  169 |       request,
  170 |       'POST',
  171 |       '/courses',
  172 |       admin.token,
  173 |       {
  174 |         course_code: `ADB${Date.now().toString().slice(-6)}`,
  175 |         course_name: 'Admin Bad Lecturer',
  176 |         semester: 'Semester 1',
  177 |         academic_year: 2026,
  178 |         lecturer_id: 'u_student_default',
  179 |       },
  180 |     );
  181 |     expect(adminCreateCourseBadLecturer.status).toBe(400);
  182 | 
  183 |     const adminCreateCourseGoodLecturer = await apiCall(
  184 |       request,
  185 |       'POST',
  186 |       '/courses',
  187 |       admin.token,
  188 |       {
  189 |         course_code: `ADG${Date.now().toString().slice(-6)}`,
  190 |         course_name: 'Admin Good Lecturer',
  191 |         semester: 'Semester 1',
  192 |         academic_year: 2026,
  193 |         lecturer_identifier: 'lecturer@ictuniversity.edu.cm',
  194 |       },
  195 |     );
  196 |     expect(adminCreateCourseGoodLecturer.status).toBe(200);
  197 | 
  198 |     const dashboard = await apiCall(request, 'GET', '/analytics/dashboard', student.token);
  199 |     expect(dashboard.status).toBe(200);
  200 |     expect(Array.isArray(dashboard.body?.courses)).toBeTruthy();
  201 | 
  202 |     // Super admin capabilities and privileged actions.
  203 |     const superRoleApprovals = await apiCall(
  204 |       request,
  205 |       'GET',
  206 |       '/admin/role-applications',
  207 |       superAdmin.token,
  208 |     );
  209 |     expect(superRoleApprovals.status).toBe(200);
  210 | 
  211 |     const lecturerSessionId = lecturerCreateSession.body?.session?.id;
  212 |     expect(lecturerSessionId).toBeTruthy();
  213 | 
  214 |     const adminManualAdd = await apiCall(request, 'POST', '/attendance/manual-add', admin.token, {
  215 |       session_id: lecturerSessionId,
  216 |       student_identifier: 'STUDENT001',
  217 |       reason: 'admin-should-fail',
  218 |     });
  219 |     expect(adminManualAdd.status).toBe(403);
  220 | 
  221 |     const superManualAdd = await apiCall(
  222 |       request,
  223 |       'POST',
  224 |       '/attendance/manual-add',
  225 |       superAdmin.token,
  226 |       {
  227 |         session_id: lecturerSessionId,
  228 |         student_identifier: 'STUDENT001',
  229 |         reason: 'super-admin-role-matrix',
  230 |       },
  231 |     );
  232 |     expect(superManualAdd.status).toBe(200);
  233 |   });
  234 | });
  235 | 
```
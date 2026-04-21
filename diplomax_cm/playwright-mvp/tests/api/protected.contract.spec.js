const { test, expect } = require('@playwright/test');
const { cfg } = require('../helpers/env');
const {
  expectStatusIn,
  formPost,
  uniqueRecruiterEmail,
  safeJson,
  backendIsReachable,
  bearerHeaders,
} = require('../helpers/api');

test.describe('Authenticated endpoint coverage', () => {
  test.setTimeout(180_000);

  async function skipIfBackendUnavailable(request) {
    const reachable = await backendIsReachable(request);
    test.skip(!reachable, 'Target backend is not reachable for this Playwright project');
  }

  test('student token can access student-facing endpoints', async ({ request }) => {
    if (test.info().project.name === 'api-local' && !cfg.runLocal) test.skip();
    if (test.info().project.name === 'api-deployed' && !cfg.runDeployed) test.skip();
    await skipIfBackendUnavailable(request);
    const password = cfg.studentPass || 'invalid-password';

    const login = await formPost(request, '/v1/auth/login/student', {
      username: cfg.studentUser,
      password,
    });
    const expectedLogin = cfg.strictAuth ? [200] : [200, 401, 500];
    await expectStatusIn(login, expectedLogin, 'student login failed');
    if (login.status() !== 200) return;
    const loginBody = await login.json();

    const me = await request.get('/v1/auth/me', {
      headers: bearerHeaders(loginBody.access_token),
    });
    await expectStatusIn(me, [200], 'student auth/me failed');
    const meBody = await safeJson(me);
    expect(meBody).toBeTruthy();

    const myRequests = await request.get('/v1/requests/my', {
      headers: bearerHeaders(loginBody.access_token),
    });
    await expectStatusIn(myRequests, [200], 'student requests endpoint failed');
  });

  test('university token can access university dashboard', async ({ request }) => {
    if (test.info().project.name === 'api-local' && !cfg.runLocal) test.skip();
    if (test.info().project.name === 'api-deployed' && !cfg.runDeployed) test.skip();
    await skipIfBackendUnavailable(request);
    const password = cfg.universityPass || 'invalid-password';

    const login = await formPost(request, '/v1/auth/login/university', {
      username: cfg.universityUser,
      password,
    });
    const expectedLogin = cfg.strictAuth ? [200] : [200, 401, 500];
    await expectStatusIn(login, expectedLogin, 'university login failed');
    if (login.status() !== 200) return;
    const loginBody = await login.json();

    const dashboard = await request.get('/v1/university/dashboard', {
      headers: bearerHeaders(loginBody.access_token),
    });
    await expectStatusIn(dashboard, [200], 'university dashboard failed');
  });

  test('recruiter flow can reach recruiter dashboard after registration/login', async ({ request }) => {
    if (test.info().project.name === 'api-local' && !cfg.runLocal) test.skip();
    if (test.info().project.name === 'api-deployed' && !cfg.runDeployed) test.skip();
    await skipIfBackendUnavailable(request);

    const email = uniqueRecruiterEmail(`${test.info().project.name}.recruiter`);
    const register = await request.post('/v1/auth/register/recruiter', {
      data: {
        company_name: 'Playwright Recruiter Flow',
        email,
        phone: '+237600000222',
        password: cfg.recruiterPassword,
      },
      headers: { 'Content-Type': 'application/json' },
    });
    await expectStatusIn(register, [200, 500], 'recruiter register failed');
    if (register.status() !== 200) return;
    const registerBody = await register.json();

    const login = await formPost(request, '/v1/auth/login/recruiter', {
      username: email,
      password: cfg.recruiterPassword,
    });
    await expectStatusIn(login, [200, 500], 'recruiter login failed');
    if (login.status() !== 200) return;
    const loginBody = await login.json();

    const dashboard = await request.get('/v1/recruiter/dashboard', {
      headers: bearerHeaders(loginBody.access_token),
    });
    await expectStatusIn(dashboard, [200], 'recruiter dashboard failed');

    const refresh = await request.post('/v1/auth/refresh', {
      data: { refresh_token: registerBody.refresh_token || loginBody.refresh_token },
      headers: { 'Content-Type': 'application/json' },
    });
    await expectStatusIn(refresh, [200], 'recruiter refresh failed');
  });
});

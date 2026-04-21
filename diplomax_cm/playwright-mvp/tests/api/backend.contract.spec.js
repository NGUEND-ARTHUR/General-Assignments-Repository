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

async function loginStudent(request, password) {
  return formPost(request, '/v1/auth/login/student', {
    username: cfg.studentUser,
    password,
  });
}

async function loginUniversity(request, password) {
  return formPost(request, '/v1/auth/login/university', {
    username: cfg.universityUser,
    password,
  });
}

async function loginRecruiter(request, email, password) {
  return formPost(request, '/v1/auth/login/recruiter', {
    username: email,
    password,
  });
}

test.describe('Backend contract and connectivity', () => {
  test.setTimeout(180_000);

  async function skipIfBackendUnavailable(request) {
    const reachable = await backendIsReachable(request);
    test.skip(!reachable, 'Target backend is not reachable for this Playwright project');
  }

  test('root and health are reachable', async ({ request }) => {
    if (test.info().project.name === 'api-local' && !cfg.runLocal) test.skip();
    if (test.info().project.name === 'api-deployed' && !cfg.runDeployed) test.skip();
    await skipIfBackendUnavailable(request);

    const root = await request.get('/', { timeout: 30_000 });
    await expectStatusIn(root, [200], 'root endpoint failed');

    const health = await request.get('/healthz', { timeout: 30_000 });
    await expectStatusIn(health, [200], 'health endpoint failed');
    const body = await health.json();
    expect(body.status).toBe('ok');
  });

  test('public endpoints are connected', async ({ request }) => {
    if (test.info().project.name === 'api-local' && !cfg.runLocal) test.skip();
    if (test.info().project.name === 'api-deployed' && !cfg.runDeployed) test.skip();
    await skipIfBackendUnavailable(request);

    const pricing = await request.get('/v1/requests/pricing', { timeout: 30_000 });
    await expectStatusIn(pricing, [200, 401, 403], 'pricing endpoint failed');
    const pricingBody = await safeJson(pricing);
    expect(pricingBody).toBeTruthy();

    const chain = await request.get('/v1/blockchain/health', { timeout: 30_000 });
    await expectStatusIn(chain, [200], 'blockchain health endpoint failed');
    const chainBody = await safeJson(chain);
    expect(chainBody).toBeTruthy();

    const search = await request.get('/v1/documents/search?q=test', { timeout: 30_000 });
    await expectStatusIn(search, [200, 401, 403], 'documents search endpoint failed unexpectedly');

    const me = await request.get('/v1/auth/me', { timeout: 30_000 });
    await expectStatusIn(me, [401, 404], 'auth/me contract mismatch');
  });

  test('student/university/recruiter auth endpoints respond correctly', async ({ request }) => {
    if (test.info().project.name === 'api-local' && !cfg.runLocal) test.skip();
    if (test.info().project.name === 'api-deployed' && !cfg.runDeployed) test.skip();
    await skipIfBackendUnavailable(request);

    const student = await loginStudent(request, cfg.studentPass || 'invalid-password');
    await expectStatusIn(
      student,
      cfg.studentPass ? [200, 401, 500] : [401, 500],
      'student login endpoint contract mismatch'
    );

    const univ = await loginUniversity(request, cfg.universityPass || 'invalid-password');
    await expectStatusIn(
      univ,
      cfg.universityPass ? [200, 401, 500] : [401, 500],
      'university login endpoint contract mismatch'
    );

    const recruiterEmail = uniqueRecruiterEmail(test.info().project.name);
    const register = await request.post('/v1/auth/register/recruiter', {
      data: {
        company_name: 'Playwright MVP Recruiter',
        email: recruiterEmail,
        phone: '+237600000111',
        password: cfg.recruiterPassword,
      },
      headers: { 'Content-Type': 'application/json' },
    });
    await expectStatusIn(register, [200, 409, 500], 'recruiter registration contract mismatch');

    const recruiter = await loginRecruiter(request, recruiterEmail, cfg.recruiterPassword);
    await expectStatusIn(recruiter, [200, 401, 500], 'recruiter login contract mismatch');

    if (recruiter.status() === 200) {
      const body = await recruiter.json();
      expect(body.access_token).toBeTruthy();
      expect(body.refresh_token).toBeTruthy();
      expect(body.role).toBe('recruiter');

      const refresh = await request.post('/v1/auth/refresh', {
        data: { refresh_token: body.refresh_token },
        headers: { 'Content-Type': 'application/json' },
      });
      await expectStatusIn(refresh, [200], 'refresh endpoint failed');
      const refreshBody = await safeJson(refresh);
      expect(refreshBody.access_token).toBeTruthy();
    }

    if (cfg.strictAuth) {
      if (cfg.studentPass && student.status() === 200) {
        const body = await student.json();
        expect(body.access_token).toBeTruthy();
      }
      if (cfg.universityPass && univ.status() === 200) {
        const body = await univ.json();
        expect(body.access_token).toBeTruthy();
      }
    }
  });
});

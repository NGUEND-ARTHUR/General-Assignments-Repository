const { expect } = require('@playwright/test');

async function expectStatusIn(response, allowed, message = '') {
  const text = await response.text();
  expect(
    allowed,
    `${message}\nStatus: ${response.status()}\nBody: ${text}`
  ).toContain(response.status());
}

async function formPost(request, path, formObj) {
  const data = new URLSearchParams(formObj).toString();
  return request.post(path, {
    data,
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });
}

function uniqueRecruiterEmail(prefix = 'pw.recruiter') {
  return `${prefix}.${Date.now()}@mailinator.com`;
}

async function safeJson(response) {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

async function backendIsReachable(request) {
  try {
    const health = await request.get('/healthz', { timeout: 30_000 });
    if (health.status() > 0) return true;
  } catch {
    // no-op
  }

  try {
    const root = await request.get('/', { timeout: 30_000 });
    return root.status() > 0;
  } catch {
    return false;
  }
}

function bearerHeaders(token) {
  return { Authorization: `Bearer ${token}` };
}

module.exports = {
  expectStatusIn,
  formPost,
  uniqueRecruiterEmail,
  safeJson,
  backendIsReachable,
  bearerHeaders,
};

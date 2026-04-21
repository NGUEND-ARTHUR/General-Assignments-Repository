// Playwright MVP for backend API validation
const { defineConfig } = require('@playwright/test');

const deployedApi = process.env.API_BASE_URL || 'https://diplomax-backend.onrender.com';
const localApi = process.env.LOCAL_API_BASE_URL || 'http://127.0.0.1:8000';
const browserName = process.env.PW_BROWSER || 'chromium';

module.exports = defineConfig({
  testDir: './tests',
  timeout: 60_000,
  expect: {
    timeout: 10_000,
  },
  fullyParallel: false,
  reporter: [['list'], ['html', { open: 'never' }]],
  projects: [
    {
      name: 'api-deployed',
      testMatch: ['api/**/*.spec.js'],
      use: {
        browserName,
        baseURL: deployedApi,
        extraHTTPHeaders: {
          Accept: 'application/json',
        },
      },
    },
    {
      name: 'api-local',
      testMatch: ['api/**/*.spec.js'],
      use: {
        browserName,
        baseURL: localApi,
        extraHTTPHeaders: {
          Accept: 'application/json',
        },
      },
    },
    {
      name: 'admin-e2e',
      testMatch: ['e2e/admin.mvp.spec.js'],
      use: {
        browserName,
        baseURL: process.env.ADMIN_WEB_URL || 'http://127.0.0.1:8080',
        trace: 'retain-on-failure',
      },
    },
    {
      name: 'student-e2e',
      testMatch: ['e2e/student.mvp.spec.js'],
      use: {
        browserName,
        baseURL: process.env.STUDENT_WEB_URL || 'http://127.0.0.1:8081',
        trace: 'retain-on-failure',
      },
    },
    {
      name: 'university-e2e',
      testMatch: ['e2e/university.mvp.spec.js'],
      use: {
        browserName,
        baseURL: process.env.UNIVERSITY_WEB_URL || 'http://127.0.0.1:8082',
        trace: 'retain-on-failure',
      },
    },
    {
      name: 'recruiter-e2e',
      testMatch: ['e2e/recruiter.mvp.spec.js'],
      use: {
        browserName,
        baseURL: process.env.RECRUITER_WEB_URL || 'http://127.0.0.1:8083',
        trace: 'retain-on-failure',
      },
    },
  ],
});

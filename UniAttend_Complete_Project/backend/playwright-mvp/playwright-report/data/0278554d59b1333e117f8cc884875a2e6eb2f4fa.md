# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: web.ui.e2e.spec.js >> UniAttend Web UI MVP - registration and negative flow >> invalid credentials show an error on the web app
- Location: tests\web.ui.e2e.spec.js:149:3

# Error details

```
Test timeout of 45000ms exceeded.
```

```
Error: expect(locator).toBeVisible() failed

Locator: getByText('Select role')
Expected: visible
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 15000ms
  - waiting for getByText('Select role')

```

# Test source

```ts
  1   | const { test, expect } = require('@playwright/test');
  2   | const { uniqueEmail, register } = require('./helpers/api');
  3   | 
  4   | const WEB_BASE_URL = process.env.PLAYWRIGHT_WEB_BASE_URL || 'http://127.0.0.1:4173';
  5   | 
  6   | const ROLE_INDEX = {
  7   |   student: 0,
  8   |   course_rep: 1,
  9   |   lecturer: 2,
  10  |   admin: 3,
  11  |   'super-admin': 4,
  12  | };
  13  | 
  14  | async function openRoleLogin(page, role) {
  15  |   await page.goto(`${WEB_BASE_URL}/role-select`);
  16  |   await page.waitForLoadState('domcontentloaded');
> 17  |   await expect(page.getByText('Select role')).toBeVisible({ timeout: 15_000 });
      |                                               ^ Error: expect(locator).toBeVisible() failed
  18  |   await page.getByRole('button', { name: 'Sign In' }).nth(ROLE_INDEX[role]).click();
  19  |   await expect(page.getByText('Welcome back')).toBeVisible({ timeout: 15_000 });
  20  | }
  21  | 
  22  | async function openRegister(page, role) {
  23  |   await page.goto(`${WEB_BASE_URL}/role-select`);
  24  |   await page.waitForLoadState('domcontentloaded');
  25  |   await expect(page.getByText('Select role')).toBeVisible({ timeout: 15_000 });
  26  |   await page.getByRole('button', { name: 'Register' }).nth(ROLE_INDEX[role]).click();
  27  |   await expect(page.getByText('Create Account')).toBeVisible({ timeout: 15_000 });
  28  | }
  29  | 
  30  | async function loginWith(page, email, password) {
  31  |   const emailInput = page.getByLabel('ICT University Email (@ictuniversity.edu.cm)');
  32  |   const passwordInput = page.getByLabel('Password');
  33  |   await expect(emailInput).toBeVisible({ timeout: 15_000 });
  34  |   await expect(passwordInput).toBeVisible({ timeout: 15_000 });
  35  |   await emailInput.fill(email);
  36  |   await passwordInput.fill(password);
  37  |   await page.getByRole('button', { name: 'Sign In' }).first().click();
  38  |   await page.waitForLoadState('networkidle');
  39  | }
  40  | 
  41  | test.describe('UniAttend Web UI MVP - student journey', () => {
  42  |   test('student can sign in, switch tabs, inspect profile, and sign out', async ({ page }) => {
  43  |     await openRoleLogin(page, 'student');
  44  |     await loginWith(page, 'student@ictuniversity.edu.cm', 'Student@1234');
  45  | 
  46  |     await expect(page.getByText('Student')).toBeVisible({ timeout: 15_000 });
  47  |     await expect(page.getByText('Hello')).toBeVisible({ timeout: 15_000 });
  48  | 
  49  |     await page.getByText('History').first().click();
  50  |     await expect(page.getByText('Recent Attendance')).toBeVisible({ timeout: 15_000 });
  51  | 
  52  |     await page.getByText('Profile').first().click();
  53  |     await expect(page.getByText('Matriculation No.')).toBeVisible({ timeout: 15_000 });
  54  | 
  55  |     await page.getByText('Home').first().click();
  56  |     await expect(page.getByText('Scan to Check In')).toBeVisible({ timeout: 15_000 });
  57  |     await page.getByRole('button', { name: 'Scan to Check In' }).first().click();
  58  |     await expect(page.getByText('Scan QR')).toBeVisible({ timeout: 15_000 });
  59  | 
  60  |     await page.locator('button:has-text("Switch to Check-Out")').click();
  61  |     await expect(page.getByText('Check-Out')).toBeVisible({ timeout: 15_000 });
  62  | 
  63  |     await page.getByText('Profile').first().click();
  64  |     await page.getByRole('button', { name: 'Sign Out' }).first().click();
  65  |     await expect(page.locator('text=Select role')).toBeVisible({ timeout: 15_000 });
  66  |   });
  67  | });
  68  | 
  69  | test.describe('UniAttend Web UI MVP - lecturer and admin journeys', () => {
  70  |   test('lecturer sees session controls and dashboard buttons', async ({ page }) => {
  71  |     await openRoleLogin(page, 'lecturer');
  72  |     await loginWith(page, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');
  73  | 
  74  |     await expect(page.getByText('Lecturer')).toBeVisible({ timeout: 15_000 });
  75  |     await expect(page.getByRole('button', { name: 'Open Dashboard' })).toBeVisible({ timeout: 15_000 });
  76  |     await expect(page.getByRole('button', { name: 'Attendance Analytics' })).toBeVisible({ timeout: 15_000 });
  77  | 
  78  |     await page.getByRole('button', { name: 'Open Dashboard' }).first().click();
  79  |     await expect(page.getByText('Create Attendance Session')).toBeVisible({ timeout: 15_000 });
  80  |     await expect(page.getByText('Open Check-Out')).toBeVisible({ timeout: 15_000 });
  81  |     await expect(page.getByText('Update Location')).toBeVisible({ timeout: 15_000 });
  82  |     await expect(page.getByText('Close Session')).toBeVisible({ timeout: 15_000 });
  83  | 
  84  |     await page.goBack();
  85  |     await page.waitForLoadState('networkidle');
  86  |     await expect(page.getByText('Lecturer')).toBeVisible({ timeout: 15_000 });
  87  |   });
  88  | 
  89  |   test('admin can access analytics and manage session actions', async ({ page }) => {
  90  |     await openRoleLogin(page, 'admin');
  91  |     await loginWith(page, 'admin@ictuniversity.edu.cm', 'Admin@1234');
  92  | 
  93  |     await expect(page.getByText('Admin')).toBeVisible({ timeout: 15_000 });
  94  |     await expect(page.getByRole('button', { name: 'Attendance Analytics' })).toBeVisible({ timeout: 15_000 });
  95  | 
  96  |     await page.getByRole('button', { name: 'Attendance Analytics' }).first().click();
  97  |     await expect(page.getByText('Attendance Analytics')).toBeVisible({ timeout: 15_000 });
  98  | 
  99  |     await page.goBack();
  100 |     await page.waitForLoadState('networkidle');
  101 |     await page.getByRole('button', { name: 'Open Dashboard' }).first().click();
  102 |     await expect(page.getByText('Session Status')).toBeVisible({ timeout: 15_000 });
  103 |     await expect(page.getByText('Create Attendance Session')).toBeVisible({ timeout: 15_000 });
  104 |   });
  105 | });
  106 | 
  107 | test.describe('UniAttend Web UI MVP - super admin journey', () => {
  108 |   test('super admin can open approvals and user management routes', async ({ page }) => {
  109 |     const applicantEmail = uniqueEmail('role_applicant');
  110 |     await register(page.request, {
  111 |       full_name: 'Playwright Applicant',
  112 |       email: applicantEmail,
  113 |       password: 'Lect@1234',
  114 |       matric_number: `APP${Date.now()}`,
  115 |       department: 'ICT',
  116 |       phone_number: '+237620000000',
  117 |       role: 'lecturer',
```
const { test, expect } = require('@playwright/test');
const { uniqueEmail, register } = require('./helpers/api');

const WEB_BASE_URL = process.env.PLAYWRIGHT_WEB_BASE_URL || 'http://127.0.0.1:4173';

const ROLE_INDEX = {
  student: 0,
  course_rep: 1,
  lecturer: 2,
  admin: 3,
  'super-admin': 4,
};

async function openRoleLogin(page, role) {
  await page.goto(`${WEB_BASE_URL}/role-select`);
  await page.waitForLoadState('domcontentloaded');
  await expect(page.getByText('Select role')).toBeVisible({ timeout: 15_000 });
  await page.getByRole('button', { name: 'Sign In' }).nth(ROLE_INDEX[role]).click();
  await expect(page.getByText('Welcome back')).toBeVisible({ timeout: 15_000 });
}

async function openRegister(page, role) {
  await page.goto(`${WEB_BASE_URL}/role-select`);
  await page.waitForLoadState('domcontentloaded');
  await expect(page.getByText('Select role')).toBeVisible({ timeout: 15_000 });
  await page.getByRole('button', { name: 'Register' }).nth(ROLE_INDEX[role]).click();
  await expect(page.getByText('Create Account')).toBeVisible({ timeout: 15_000 });
}

async function loginWith(page, email, password) {
  const emailInput = page.getByLabel('ICT University Email (@ictuniversity.edu.cm)');
  const passwordInput = page.getByLabel('Password');
  await expect(emailInput).toBeVisible({ timeout: 15_000 });
  await expect(passwordInput).toBeVisible({ timeout: 15_000 });
  await emailInput.fill(email);
  await passwordInput.fill(password);
  await page.getByRole('button', { name: 'Sign In' }).first().click();
  await page.waitForLoadState('networkidle');
}

test.describe('UniAttend Web UI MVP - student journey', () => {
  test('student can sign in, switch tabs, inspect profile, and sign out', async ({ page }) => {
    await openRoleLogin(page, 'student');
    await loginWith(page, 'student@ictuniversity.edu.cm', 'Student@1234');

    await expect(page.getByText('Student')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Hello')).toBeVisible({ timeout: 15_000 });

    await page.getByText('History').first().click();
    await expect(page.getByText('Recent Attendance')).toBeVisible({ timeout: 15_000 });

    await page.getByText('Profile').first().click();
    await expect(page.getByText('Matriculation No.')).toBeVisible({ timeout: 15_000 });

    await page.getByText('Home').first().click();
    await expect(page.getByText('Scan to Check In')).toBeVisible({ timeout: 15_000 });
    await page.getByRole('button', { name: 'Scan to Check In' }).first().click();
    await expect(page.getByText('Scan QR')).toBeVisible({ timeout: 15_000 });

    await page.locator('button:has-text("Switch to Check-Out")').click();
    await expect(page.getByText('Check-Out')).toBeVisible({ timeout: 15_000 });

    await page.getByText('Profile').first().click();
    await page.getByRole('button', { name: 'Sign Out' }).first().click();
    await expect(page.locator('text=Select role')).toBeVisible({ timeout: 15_000 });
  });
});

test.describe('UniAttend Web UI MVP - lecturer and admin journeys', () => {
  test('lecturer sees session controls and dashboard buttons', async ({ page }) => {
    await openRoleLogin(page, 'lecturer');
    await loginWith(page, 'lecturer@ictuniversity.edu.cm', 'Lect@1234');

    await expect(page.getByText('Lecturer')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Open Dashboard' })).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Attendance Analytics' })).toBeVisible({ timeout: 15_000 });

    await page.getByRole('button', { name: 'Open Dashboard' }).first().click();
    await expect(page.getByText('Create Attendance Session')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Open Check-Out')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Update Location')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Close Session')).toBeVisible({ timeout: 15_000 });

    await page.goBack();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Lecturer')).toBeVisible({ timeout: 15_000 });
  });

  test('admin can access analytics and manage session actions', async ({ page }) => {
    await openRoleLogin(page, 'admin');
    await loginWith(page, 'admin@ictuniversity.edu.cm', 'Admin@1234');

    await expect(page.getByText('Admin')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Attendance Analytics' })).toBeVisible({ timeout: 15_000 });

    await page.getByRole('button', { name: 'Attendance Analytics' }).first().click();
    await expect(page.getByText('Attendance Analytics')).toBeVisible({ timeout: 15_000 });

    await page.goBack();
    await page.waitForLoadState('networkidle');
    await page.getByRole('button', { name: 'Open Dashboard' }).first().click();
    await expect(page.getByText('Session Status')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Create Attendance Session')).toBeVisible({ timeout: 15_000 });
  });
});

test.describe('UniAttend Web UI MVP - super admin journey', () => {
  test('super admin can open approvals and user management routes', async ({ page }) => {
    const applicantEmail = uniqueEmail('role_applicant');
    await register(page.request, {
      full_name: 'Playwright Applicant',
      email: applicantEmail,
      password: 'Lect@1234',
      matric_number: `APP${Date.now()}`,
      department: 'ICT',
      phone_number: '+237620000000',
      role: 'lecturer',
      role_justification: 'Needed for super admin approvals test',
    });

    await openRoleLogin(page, 'super-admin');
    await loginWith(page, 'nguend.johann@ictuniversity.edu.cm', 'Arthutr@ictu2024');

    await expect(page.getByText('Super Admin')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Role Approvals' })).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Attendance Analytics' })).toBeVisible({ timeout: 15_000 });

    await page.getByRole('button', { name: 'Role Approvals' }).first().click();
    await expect(page.getByText('Role Approvals')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Approve' })).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Reject' })).toBeVisible({ timeout: 15_000 });

    await page.goto(`${WEB_BASE_URL}/super-admin/users`);
    await page.waitForLoadState('networkidle');
    await expect(page.getByText('Super Admin User Management')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Edit' }).first()).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: /Block|Unblock/ }).first()).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Delete' }).first()).toBeVisible({ timeout: 15_000 });
  });
});

test.describe('UniAttend Web UI MVP - registration and negative flow', () => {
  test('registration screen is reachable from the role selector', async ({ page }) => {
    await openRegister(page, 'student');
    await expect(page.getByText('Create Account')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Role Application')).toBeVisible({ timeout: 15_000 });
  });

  test('invalid credentials show an error on the web app', async ({ page }) => {
    await openRoleLogin(page, 'student');
    await loginWith(page, 'invalid@ictuniversity.edu.cm', 'WrongPassword123');
    await expect(page.getByText(/Invalid/i)).toBeVisible({ timeout: 15_000 });
  });
});

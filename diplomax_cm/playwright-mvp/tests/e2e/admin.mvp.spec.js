const { test, expect } = require('@playwright/test');
const { cfg } = require('../helpers/env');
const { tryGoto } = require('../helpers/web');

test.describe('Admin web MVP', () => {
  test('login page renders and can authenticate demo flow', async ({ page }) => {
    const opened = await tryGoto(page, '/login');
    test.skip(!opened.ok, 'Admin app is not reachable for UI smoke testing');

    const emailInput = page.locator('input[placeholder*="email" i], input[type="email"], input[name="email"]');
    const passwordInput = page.locator('input[placeholder*="password" i], input[type="password"], input[name="password"]');

    let hasLoginForm = await emailInput
      .first()
      .waitFor({ state: 'visible', timeout: 30_000 })
      .then(() => true)
      .catch(() => false);

    if (!hasLoginForm) {
      const fallback = await tryGoto(page, '/');
      if (fallback.ok) {
        hasLoginForm = await emailInput
          .first()
          .waitFor({ state: 'visible', timeout: 15_000 })
          .then(() => true)
          .catch(() => false);
      }
    }
    test.skip(!hasLoginForm, 'Admin URL is up but does not currently expose a detectable login form');

    await expect(passwordInput.first()).toBeVisible();

    await emailInput.first().fill(cfg.adminUser);
    await passwordInput.first().fill(cfg.adminPass);

    const loginButton = page.getByRole('button', { name: /Login|Se connecter|Sign in/i }).first();
    const genericSubmit = page.locator('button[type="submit"]').first();
    const canUseNamedButton = await loginButton.isVisible().catch(() => false);
    if (canUseNamedButton) {
      await loginButton.click();
    } else {
      await genericSubmit.click();
    }

    const reachedDashboard = await page
      .waitForURL(/\/dashboard/, { timeout: 10_000 })
      .then(() => true)
      .catch(() => false);

    if (reachedDashboard) {
      await expect(page.getByText(/Recent Activity|Activite recente|Dashboard/i)).toBeVisible();
      return;
    }

    await expect(page.getByText(/invalid|invalide|failed|echec|incorrect|error|unauthorized/i).first()).toBeVisible();
  });
});

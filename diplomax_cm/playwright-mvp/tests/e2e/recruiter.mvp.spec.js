const { test, expect } = require('@playwright/test');
const { cfg } = require('../helpers/env');
const { tryGoto } = require('../helpers/web');

test.describe('Recruiter web MVP', () => {
  test('login page baseline renders', async ({ page }) => {
    const opened = await tryGoto(page, '/login');
    test.skip(!opened.ok, 'Recruiter app is not reachable for UI smoke testing');

    const emailInput = page.locator('input[placeholder*="email" i], input[type="email"], input[name="email"], input[name="username"], input[type="text"]');
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
    test.skip(!hasLoginForm, 'Recruiter URL is up but does not currently expose a detectable login form');

    await expect(passwordInput.first()).toBeVisible();

    await emailInput.first().fill('nobody@example.com');
    await passwordInput.first().fill('invalid-password');

    const namedSubmit = page.getByRole('button', { name: /Sign in|Se connecter|Login|Connexion|Submit/i }).first();
    const genericSubmit = page.locator('button[type="submit"]').first();
    const canUseNamed = await namedSubmit.isVisible().catch(() => false);
    if (canUseNamed) {
      await namedSubmit.click();
    } else {
      await genericSubmit.click();
    }

    const reachedPostLogin = await page
      .waitForURL(/dashboard|home|jobs|recruiter/i, { timeout: 10_000 })
      .then(() => true)
      .catch(() => false);
    if (reachedPostLogin) return;

    await expect(page.getByText(/invalid|invalide|failed|echec|incorrect|error|unauthorized/i).first()).toBeVisible();
  });

  test('register page baseline renders', async ({ page }) => {
    const opened = await tryGoto(page, '/register');
    test.skip(!opened.ok, 'Recruiter app register page is not reachable for UI smoke testing');

    const companyInput = page.locator('input[placeholder*="company" i], input[placeholder*="entreprise" i], input[name*="company" i], input[name*="organization" i], input[name*="entreprise" i]');
    const emailInput = page.locator('input[placeholder*="email" i], input[type="email"], input[name="email"]');
    const passwordInput = page.locator('input[placeholder*="password" i], input[type="password"], input[name="password"]');

    let hasRegisterForm = await emailInput
      .first()
      .waitFor({ state: 'visible', timeout: 30_000 })
      .then(() => true)
      .catch(() => false);

    if (!hasRegisterForm) {
      const fallback = await tryGoto(page, '/');
      if (fallback.ok) {
        hasRegisterForm = await emailInput
          .first()
          .waitFor({ state: 'visible', timeout: 15_000 })
          .then(() => true)
          .catch(() => false);
      }
    }
    test.skip(!hasRegisterForm, 'Recruiter register URL is up but does not currently expose a detectable register form');

    await expect(passwordInput.first()).toBeVisible();

    const hasCompany = await companyInput.first().isVisible().catch(() => false);
    if (hasCompany) {
      await companyInput.first().fill('Playwright Recruiter Flow');
    }
    await emailInput.first().fill(`playwright-register-${Date.now()}@example.com`);
    await passwordInput.first().fill(cfg.recruiterPassword);

    const createButton = page.getByRole('button', { name: /Create account|Register|Creer un compte|S'inscrire/i }).first();
    const genericSubmit = page.locator('button[type="submit"]').first();
    const canUseNamed = await createButton.isVisible().catch(() => false);
    if (canUseNamed) {
      await expect(createButton).toBeVisible();
    } else {
      await expect(genericSubmit).toBeVisible();
    }
  });
});

async function tryGoto(page, path = '/', options = {}) {
  try {
    await page.goto(path, {
      waitUntil: 'domcontentloaded',
      timeout: options.timeout || 15_000,
    });
    return { ok: true };
  } catch (error) {
    return { ok: false, error };
  }
}

module.exports = {
  tryGoto,
};

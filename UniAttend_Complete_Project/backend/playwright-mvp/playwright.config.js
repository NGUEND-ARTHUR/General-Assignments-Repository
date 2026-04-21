const { defineConfig } = require('@playwright/test');
const path = require('path');

const backendRoot = path.resolve(__dirname, '..');
const frontendRoot = path.resolve(__dirname, '..', '..', 'flutter_app');

module.exports = defineConfig({
  testDir: './tests',
  timeout: 45_000,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://127.0.0.1:8000',
    trace: 'retain-on-failure',
  },
  webServer: [
    {
      command: `cmd /c "cd /d ${backendRoot} && .venv\\Scripts\\python.exe start_server.py"`,
      url: 'http://127.0.0.1:8000/health',
      timeout: 90_000,
      reuseExistingServer: true,
    },
    {
      command:
        `cmd /c "cd /d ${frontendRoot} && flutter run -d web-server --web-hostname 127.0.0.1 --web-port 4173 --dart-define=UNIATTEND_API_BASE_URL=http://127.0.0.1:8000"`,
      url: 'http://127.0.0.1:4173',
      timeout: 240_000,
      reuseExistingServer: false,
    },
  ],
});

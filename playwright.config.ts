import { defineConfig, devices } from '@playwright/test';

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// import dotenv from 'dotenv';
// import path from 'path';
// dotenv.config({ path: path.resolve(__dirname, '.env') });

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './e2e',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('')`. */
    baseURL: 'http://localhost:4001',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',

    /** Global timeout per action (click, fill, etc.). */
    actionTimeout: 10_000,
  },
  /** Default timeout for each test (ms). */
  timeout: 30_000,

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },

    /* Test against mobile viewports. */
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'] },
    // },

    /* Test against branded browsers. */
    // {
    //   name: 'Microsoft Edge',
    //   use: { ...devices['Desktop Edge'], channel: 'msedge' },
    // },
    // {
    //   name: 'Google Chrome',
    //   use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    // },
  ],

  /* Run your local dev server before starting the tests */
  webServer: [
    {
      // Google OAuth mock — must start before Phoenix so env var GOOGLE_OAUTH_BASE_URL is valid
      command: 'node e2e/support/mock-api-server.cjs',
      url: 'http://localhost:4444/health',
      reuseExistingServer: !process.env.CI,
      timeout: 30_000,
    },
    {
     /**
       * Start Phoenix with the mock base URLs injected so Groq/OpenAI calls
       * hit the local mock server instead of the real internet.
       *
       * On CI a fresh server is always started.
       * Locally, if Phoenix is already running it is reused (make sure you
       * started it with the same env vars — see comment at the top of this file).
       */
      command: 'mix phx.server',
      url: 'http://localhost:4001',
      reuseExistingServer: !process.env.CI,
      timeout: 120_000,
      env: {
        PORT: '4001',
        GOOGLE_OAUTH_BASE_URL: 'http://localhost:4444/google',
        // Provide dummy Google credentials so the OAuth module doesn't raise
        // on startup when the real env vars aren't set in the test environment.
        GOOGLE_OAUTH_CLIENT_ID: 'mock-client-id-for-e2e-tests',
        GOOGLE_OAUTH_CLIENT_SECRET: 'mock-client-secret-for-e2e-tests',
        GOOGLE_OAUTH_REDIRECT_URI: 'http://localhost:4001/auth/google/callback',
      },
    }
  ],
});

import { test, expect, type Page } from '@playwright/test';

/**
 * Koveriders — Rider Page (/@handle)
 *
 * These tests cover the public rider profile page — the shareable URL
 * that riders post in Facebook groups.
 *
 * Test strategy:
 *  - Unknown handle → LiveView redirects to / with an error flash
 *  - Known handle   → public page renders correctly (heading, share button,
 *                     OG meta tags, empty-garage state)
 *  - Nav link       → the rider's handle link is visible in the header after login
 *  - Settings       → handle form section is present in account settings
 *
 * The "known handle" tests require a real DB user. We reuse the same Google
 * OAuth mock user (e2e-rider@test.kove) for all tests, log in to grab the
 * auto-generated handle from the handle nav link, then visit the rider page.
 *
 * Auth flow:
 *   /users/log-in → click "Continue with Google" → mock server returns the
 *   test user → Phoenix creates/finds the user → redirects to /garage
 */

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function waitForLiveSocket(page: Page): Promise<void> {
  await page.waitForFunction(
    () => (window as any).liveSocket?.isConnected() === true,
    { timeout: 10_000 }
  );
}

/**
 * Log in via the Google OAuth mock flow and return the rider handle scraped
 * from the handle nav link (href="/@<handle>").
 */
async function loginAndGetHandle(page: Page): Promise<string> {
  await page.goto('/users/log-in');
  await waitForLiveSocket(page);
  await page.getByRole('link', { name: /continue with google/i }).click();
  // After successful OAuth the app redirects to /garage
  await page.waitForURL('/garage', { timeout: 15_000 });

  // The nav renders <a href="/@<handle>">{handle}</a> for logged-in users
  const handleLink = page.locator('a[href^="/@"]').first();
  await expect(handleLink).toBeVisible({ timeout: 5_000 });
  const href = await handleLink.getAttribute('href');
  // href is "/@motomike_1234" → strip "/@"
  return href!.slice(2);
}

// ---------------------------------------------------------------------------
// Unknown handle — 404 redirect
// ---------------------------------------------------------------------------

test.describe('Rider page — unknown handle', () => {
  test('redirects to the storefront and shows an error flash', async ({ page }) => {
    await page.goto('/@this-handle-does-not-exist-xyz');
    await waitForLiveSocket(page);

    // LiveView redirects to /
    await expect(page).toHaveURL(/\/$/, { timeout: 10_000 });

    // Error flash message from put_flash(:error, "Rider not found.")
    await expect(page.getByText(/rider not found/i)).toBeVisible();
  });
});

// ---------------------------------------------------------------------------
// Known handle — public page structure
// ---------------------------------------------------------------------------

test.describe('Rider page — page structure', () => {
  let handle = '';

  test.beforeEach(async ({ page }) => {
    handle = await loginAndGetHandle(page);
    console.log(`[test setup] Logged in as @${handle}`);
    await page.goto(`/@${handle}`);
    await waitForLiveSocket(page);
  });

  test('has the correct page title', async ({ page }) => {
    // assign(:page_title, "@#{rider.handle} — KoveRiders")
    await expect(page).toHaveTitle(new RegExp(handle, 'i'));
  });

  test('displays @handle as the main heading', async ({ page }) => {
    // <h1>@{@rider.handle}</h1>
    const heading = page.getByRole('heading', { level: 1 });
    await expect(heading).toBeVisible();
    await expect(heading).toContainText(`@${handle}`);
  });

  test('shows the empty-garage state when no bike is registered', async ({ page }) => {
    // <p>{@rider.handle} hasn't added any bikes yet.</p>
    await expect(
      page.getByText(/hasn't added any bikes yet/i)
    ).toBeVisible();
  });

  test('shows the Share button', async ({ page }) => {
    // <button onclick="navigator.clipboard..."><.icon .../> Share</button>
    await expect(page.getByRole('button', { name: /share/i })).toBeVisible();
  });

  test('is publicly accessible without login', async ({ browser }) => {
    // Open a brand-new context with no session cookies
    const ctx = await browser.newContext();
    const freshPage = await ctx.newPage();
    await freshPage.goto(`/@${handle}`);
    await waitForLiveSocket(freshPage);

    await expect(
      freshPage.getByRole('heading', { level: 1 })
    ).toContainText(`@${handle}`);

    await ctx.close();
  });
});

// ---------------------------------------------------------------------------
// Open Graph meta tags
// ---------------------------------------------------------------------------

test.describe('Rider page — Open Graph meta tags', () => {
  let handle = '';

  test.beforeEach(async ({ page }) => {
    handle = await loginAndGetHandle(page);
  });

  test('og:title contains the handle', async ({ page }) => {
    // assign(:og_title, "@#{rider.handle} — KoveRiders")
    await page.goto(`/@${handle}`);
    const ogTitle = page.locator('meta[property="og:title"]');
    await expect(ogTitle).toHaveAttribute('content', new RegExp(handle, 'i'));
  });

  test('og:description is set', async ({ page }) => {
    await page.goto(`/@${handle}`);
    const ogDesc = page.locator('meta[property="og:description"]');
    await expect(ogDesc).toHaveAttribute('content', /.+/);
  });

  test('og:url points to the rider page', async ({ page }) => {
    await page.goto(`/@${handle}`);
    const ogUrl = page.locator('meta[property="og:url"]');
    await expect(ogUrl).toHaveAttribute('content', new RegExp(`/@${handle}`));
  });

  test('og:type is "profile" on the rider page', async ({ page }) => {
    // assign(:og_type, "profile") set in RiderPageLive.mount/3
    await page.goto(`/@${handle}`);
    const ogType = page.locator('meta[property="og:type"]');
    await expect(ogType).toHaveAttribute('content', 'profile');
  });

  test('twitter:card is set', async ({ page }) => {
    await page.goto(`/@${handle}`);
    const twitterCard = page.locator('meta[name="twitter:card"]');
    await expect(twitterCard).toHaveAttribute('content', 'summary_large_image');
  });

  test('homepage og:type is "website" (not "profile")', async ({ page }) => {
    // root.html.heex: assigns[:og_type] || "website"
    await page.goto('/');
    const ogType = page.locator('meta[property="og:type"]');
    await expect(ogType).toHaveAttribute('content', 'website');
  });
});

// ---------------------------------------------------------------------------
// Navigation — handle nav link
// ---------------------------------------------------------------------------

test.describe('Rider page — nav link', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/users/log-in');
    await waitForLiveSocket(page);
    await page.getByRole('link', { name: /continue with google/i }).click();
    await page.waitForURL('/garage', { timeout: 15_000 });
  });

  test('shows the handle nav link in the header when logged in', async ({ page }) => {
    // <.link navigate={~p"/@#{@current_scope.user.handle}"}>
    const handleLink = page.locator('a[href^="/@"]').first();
    await expect(handleLink).toBeVisible();
  });

  test('handle nav link href is /@<handle>', async ({ page }) => {
    const handleLink = page.locator('a[href^="/@"]').first();
    await expect(handleLink).toBeVisible();
    await expect(handleLink).toHaveAttribute('href', /^\/@[a-z0-9_]+$/);
  });

  test('clicking the handle nav link navigates to the rider page', async ({ page }) => {
    // Wait for the "Signed in" flash to clear so it doesn't overlap the nav bar
    await page
      .locator('#flash-group')
      .getByText(/signed in/i)
      .waitFor({ state: 'hidden', timeout: 10_000 })
      .catch(() => {});

    const handleLink = page.locator('a[href^="/@"]').first();
    await handleLink.click();
    await expect(page).toHaveURL(/\/@[a-z0-9_]+$/, { timeout: 10_000 });
  });
});

// ---------------------------------------------------------------------------
// Settings — handle form
// ---------------------------------------------------------------------------

test.describe('Rider page — settings handle form', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/users/log-in');
    await waitForLiveSocket(page);
    await page.getByRole('link', { name: /continue with google/i }).click();
    await page.waitForURL('/garage', { timeout: 15_000 });
    await page.goto('/users/settings');
    await waitForLiveSocket(page);
  });

  test('shows the handle form', async ({ page }) => {
    // id="handle-form" (hyphen) set in settings.ex template
    await expect(page.locator('#handle-form')).toBeVisible();
  });

  test('shows the "Your Rider Handle" section heading', async ({ page }) => {
    // <h2 class="card-title">Your Rider Handle</h2>
    await expect(page.getByText('Your Rider Handle')).toBeVisible();
  });

  test('shows the live preview URL with the current handle', async ({ page }) => {
    // koveriders.com/@{@user.handle}
    await expect(page.getByText(/koveriders\.com\/@/)).toBeVisible();
  });
});

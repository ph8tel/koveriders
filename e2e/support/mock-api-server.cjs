'use strict';

/**
 * Lightweight mock HTTP server for Google OAuth
 *
 *
 *   node e2e/support/mock-api-server.cjs
 *   PORT=4444 node e2e/support/mock-api-server.cjs  # explicit port
 *
 * Endpoints:
 *   GET  /health                          → 200 "OK"  (Playwright ready-check)
 *   POST /openai/v1/chat/completions      → SSE stream mimicking the Groq API
 *   POST /v1/embeddings                   → JSON embedding mimicking OpenAI
 */

const http = require('http');

const PORT = parseInt(process.env.PORT ?? '4444', 10);

/**
 * Fake Google OAuth user returned by the mock userinfo endpoint.
 * Using a dedicated E2E test email keeps the mock user isolated from real accounts.
 */
const MOCK_GOOGLE_USER = {
  sub: 'mock_google_sub_e2e_test_001',
  email: 'e2e-rider@test.kove',
  name: 'E2E Test Rider',
  email_verified: true,
};

/**
 * GET /google/o/oauth2/v2/auth
 *
 * Fake Google authorization page. Instead of showing a consent screen it
 * immediately redirects back to the app's callback URL with a mock code and
 * the original state token so the CSRF check passes.
 */
function handleGoogleAuth(req, res) {
  const url = new URL(`http://localhost${req.url}`);
  const redirectUri = url.searchParams.get('redirect_uri');
  const state = url.searchParams.get('state');

  if (!redirectUri) {
    res.writeHead(400, { 'Content-Type': 'text/plain' });
    res.end('Missing redirect_uri');
    return;
  }

  const callbackUrl = new URL(redirectUri);
  callbackUrl.searchParams.set('code', 'mock_google_auth_code');
  if (state) callbackUrl.searchParams.set('state', state);

  res.writeHead(302, { Location: callbackUrl.toString() });
  res.end();
}

/**
 * POST /google/oauth2/token
 *
 * Returns a fake access token JSON response, matching the shape that
 * Google's real token endpoint returns.
 */
function handleGoogleToken(res) {
  const body = JSON.stringify({
    access_token: 'mock_google_access_token',
    token_type: 'Bearer',
    expires_in: 3600,
    scope: 'openid email profile',
  });
  res.writeHead(200, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

/**
 * GET /google/oauth2/v3/userinfo
 *
 * Returns a fake Google user profile so Phoenix can look up or create the
 * user and complete the OAuth login flow.
 */
function handleGoogleUserInfo(res) {
  const body = JSON.stringify(MOCK_GOOGLE_USER);
  res.writeHead(200, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}


// ---------------------------------------------------------------------------
// Server
// ---------------------------------------------------------------------------

const server = http.createServer((req, res) => {
  // Consume the request body before responding (required for POST requests)
  let _body = '';
  req.on('data', (chunk) => {
    _body += chunk;
  });
  req.on('end', async () => {
    if (req.method === 'GET' && req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end('OK');
    } else if (req.method === 'GET' && req.url?.startsWith('/google/o/oauth2/v2/auth')) {
      handleGoogleAuth(req, res);
    } else if (req.method === 'POST' && req.url === '/google/oauth2/token') {
      handleGoogleToken(res);
    } else if (req.method === 'GET' && req.url === '/google/oauth2/v3/userinfo') {
      handleGoogleUserInfo(res);
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end(`Not found: ${req.method} ${req.url}\n`);
    }
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[mock-api-server] Ready on http://localhost:${PORT}`);
  console.log(`  Google User info -> GET /google/oauth2/v3/userinfo`);
  console.log(`  Google OAuth → POST /google/oauth2/token`);
  console.log(`  Health → GET  /health`);
});

for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => {
    server.close(() => {
      console.log('[mock-api-server] Stopped');
      process.exit(0);
    });
  });
}

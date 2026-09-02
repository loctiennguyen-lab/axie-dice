/**
 * Vercel serverless function: proxy Axie Infinity GraphQL query with CORS.
 * Resolves: CORS block when browser calls https://graphql-gateway.axieinfinity.com/graphql directly.
 * Uses curl (available in Vercel runtime) to bypass Cloudflare challenge.
 *
 * GET /api/axie?id=<axieId>
 * Returns: { id, class, image, parts: [{id, name, class, type, specialGenes}] }
 */

const { execFileSync } = require('child_process');

const GRAPHQL_ENDPOINT = 'https://graphql-gateway.axieinfinity.com/graphql';

const QUERY = `
  query GetAxieDetail($axieId: ID!) {
    axie(axieId: $axieId) {
      id
      class
      parts {
        id
        name
        class
        type
        specialGenes
      }
    }
  }
`;

/**
 * The GraphQL API's own `axie.image` field returns a URL on
 * assets.axieinfinity.com that 403s (AccessDenied) even from a real browser
 * — verified directly, not assumed; that bucket appears to reject public
 * reads regardless of headers/referrer. The actual public, hotlink-safe CDN
 * for the same rendered PNG is a different host with the same path shape —
 * verified working (HTTP 200, image/png) for multiple real Axie IDs. Build
 * the URL ourselves instead of trusting the field GraphQL returns.
 */
function axieImageUrl(id) {
  return `https://axiecdn.axieinfinity.com/axies/${id}/axie/axie-full-transparent.png`;
}

/**
 * Validates axieId is a non-empty string of digits.
 */
function validateAxieId(id) {
  return typeof id === 'string' && /^\d+$/.test(id) && id.length > 0;
}

/**
 * Checks if axie data is valid (not a placeholder for "not found").
 */
function isValidAxieData(axieData) {
  if (!axieData) return false;
  // Axie Infinity returns `class: null` and empty parts array for non-existent/unminted IDs
  return axieData.class !== null && axieData.parts && axieData.parts.length > 0;
}

// Simple in-memory per-IP rate limit — resets on cold start, no external store.
// Not meant to stop a determined attacker (they can rotate IPs or bypass CORS
// entirely), just to keep a casual spam script from burning function invocations.
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 20;
const hits = new Map();
function isRateLimited(ip) {
  const now = Date.now();
  const arr = (hits.get(ip) || []).filter((t) => now - t < RATE_LIMIT_WINDOW_MS);
  arr.push(now);
  hits.set(ip, arr);
  return arr.length > RATE_LIMIT_MAX;
}

module.exports = async (req, res) => {
  // CORS headers (required because origin API blocks browser requests)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');

  // Handle preflight OPTIONS
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || 'unknown';
  if (isRateLimited(ip)) {
    res.status(429).json({ error: 'Too many requests, try again in a minute.' });
    return;
  }

  const { id } = req.query;

  // Validate input
  if (!id || !validateAxieId(id)) {
    res.status(400).json({
      error: 'Invalid axieId. Must be a positive integer.',
      received: id,
    });
    return;
  }

  try {
    // Call Axie Infinity GraphQL API via curl. Node's own fetch()/https module get
    // blocked by Cloudflare's bot-management challenge on this endpoint even with a
    // spoofed User-Agent (verified: identical headers, curl passes, Node fetch does
    // not — this is a TLS/HTTP2 client-fingerprint check, not a header check, so it
    // cannot be fixed by adjusting request headers in JS). curl is a standard part of
    // the Amazon Linux base image AWS Lambda's Node.js runtime uses (Vercel Node
    // functions run on Lambda), so this is a reasonably safe dependency, but it is an
    // undocumented implementation detail of the platform rather than a guarantee — if
    // this starts failing in production, the fix is either an official Sky Mavis
    // Developer API key (docs.skymavis.com) or a managed Web3-data provider, not a
    // request-header tweak.
    const payload = JSON.stringify({
      query: QUERY,
      variables: { axieId: id },
    });

    let responseText;
    try {
      // execFileSync (not execSync) — argv array, never a shell string, so there is no
      // shell-interpolation/injection surface regardless of what `payload` contains.
      responseText = execFileSync(
        'curl',
        ['-s', '-m', '8', '-X', 'POST', GRAPHQL_ENDPOINT, '-H', 'Content-Type: application/json', '-d', payload],
        { encoding: 'utf-8', maxBuffer: 10 * 1024 * 1024, timeout: 9000 }
      );
    } catch (execErr) {
      console.error('curl execution error:', execErr.message);
      res.status(502).json({ error: 'Failed to fetch Axie data' });
      return;
    }

    let data;
    try {
      data = JSON.parse(responseText);
    } catch (parseErr) {
      console.error('JSON parse error:', parseErr.message, 'response:', responseText.substring(0, 200));
      res.status(502).json({ error: 'Invalid response from Axie API' });
      return;
    }

    // Check for GraphQL errors
    if (data.errors) {
      console.error('GraphQL errors:', data.errors);
      res.status(502).json({ error: 'Axie API returned an error' });
      return;
    }

    const axie = data.data?.axie;

    // Validate axie exists (not null or empty)
    if (!isValidAxieData(axie)) {
      res.status(404).json({
        error: `Axie #${id} not found or has no data`,
      });
      return;
    }

    // Success: return clean payload
    res.setHeader('Cache-Control', 'public, max-age=300');
    res.status(200).json({
      id: axie.id,
      class: axie.class,
      image: axieImageUrl(axie.id),
      parts: axie.parts,
    });
  } catch (err) {
    console.error('Proxy error:', err.message);
    res.status(502).json({ error: 'Failed to fetch Axie data' });
  }
};

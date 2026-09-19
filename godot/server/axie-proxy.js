/**
 * Axie lookup proxy for the GODOT build.
 *
 * WHY THIS FILE EXISTS
 * --------------------
 * A browser cannot fetch the Axie gateway itself: the gateway sends no CORS headers, so the
 * response is unreadable from page JavaScript. And a plain server-side `fetch()` cannot either —
 * Cloudflare bot management checks the TLS/HTTP2 client fingerprint, which no header can fake.
 * `curl` is the one client that gets through. So a web build of the Godot port needs a server,
 * and this is it.
 *
 * The desktop build does NOT need this — it runs `curl` locally (see godot/scripts/net/axie_api.gd).
 * This is only for a browser export.
 *
 * DELIBERATELY NOT `api/axie.js`
 * ------------------------------
 * That file serves the LIVE JavaScript game and real players. This one is separate so the Godot
 * port can gain a field, change a shape, or be rate-limited differently without any of it
 * reaching a player of the other build. The only difference in output today is `genes` — the
 * 512-bit `newGenes`, which the Godot 3D rig needs and the JS build has never asked for.
 *
 * DEPLOY: see README.md next to this file.
 *
 * GET ?id=<axieId>  ->  { id, class, genes, parts: [{id, name, class, type, specialGenes}] }
 */

const { execFileSync } = require('child_process');

const GRAPHQL_ENDPOINT = 'https://graphql-gateway.axieinfinity.com/graphql';

/**
 * `newGenes`, NOT `genes`.
 *
 * Both exist and both return a hex string, which is what makes picking the wrong one dangerous:
 * `genes` is the original 256-bit format (66 chars), `newGenes` is the 512-bit Origin format
 * (130). Godot's `AxieDescriptor.from_genes()` is a 512-bit decoder — handed the short one it
 * does not throw, it decodes nonsense and builds a confident, wrong Axie.
 */
const QUERY = `
  query GetAxieDetail($axieId: ID!) {
    axie(axieId: $axieId) {
      id
      class
      newGenes
      parts { id name class type specialGenes }
    }
  }
`;

function isValidAxieId(id) {
  return typeof id === 'string' && /^[1-9]\d{0,11}$/.test(id);
}

// Per-IP rate limit, in memory. Resets on cold start and is trivially bypassed by rotating IPs —
// it is here to stop a careless loop burning invocations, not to stop an attacker.
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
  // A Godot web export is served from its own origin, so CORS has to be open for it to read this.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || 'unknown';
  if (isRateLimited(ip)) {
    return res.status(429).json({ error: 'Too many requests, try again in a minute.' });
  }

  const id = String((req.query && req.query.id) || '');
  if (!isValidAxieId(id)) {
    return res.status(400).json({ error: 'Invalid axieId. Must be a positive integer.' });
  }

  let responseText;
  try {
    // execFileSync with an argv ARRAY — never a shell string, so there is no interpolation to
    // inject into regardless of what the payload contains. `id` is digits-only by the check above.
    responseText = execFileSync(
      'curl',
      ['-s', '-m', '8', '-X', 'POST', GRAPHQL_ENDPOINT,
        '-H', 'Content-Type: application/json',
        '-d', JSON.stringify({ query: QUERY, variables: { axieId: id } })],
      { encoding: 'utf-8', maxBuffer: 10 * 1024 * 1024, timeout: 9000 }
    );
  } catch (err) {
    console.error('curl failed:', err.message);
    return res.status(502).json({ error: 'Failed to fetch Axie data' });
  }

  let data;
  try {
    data = JSON.parse(responseText);
  } catch (err) {
    console.error('bad JSON from gateway:', responseText.slice(0, 200));
    return res.status(502).json({ error: 'Invalid response from Axie API' });
  }
  if (data.errors) {
    console.error('GraphQL errors:', JSON.stringify(data.errors).slice(0, 300));
    return res.status(502).json({ error: 'Axie API returned an error' });
  }

  const axie = data.data && data.data.axie;
  // An unminted or non-existent id comes back as a null axie, or with a null class and no parts.
  if (!axie || axie.class === null || !axie.parts || axie.parts.length === 0) {
    return res.status(404).json({ error: `Axie #${id} not found` });
  }

  res.setHeader('Cache-Control', 'public, max-age=300');
  return res.status(200).json({
    id: axie.id,
    class: axie.class,
    genes: axie.newGenes || '',
    parts: axie.parts,
  });
};

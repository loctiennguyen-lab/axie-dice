// Terms and Privacy pages: linked from the Google OAuth consent screen (Branding) and the game.
// Served by the Worker itself rather than uploaded to R2, so they live in git next to the code
// that does what they describe, and change with one `wrangler deploy`.
//
// Keep these TRUE. When the game starts storing something new, the privacy page changes in the
// same commit.

const CONTACT = 'loc.tien.nguyen@skymavis.com';
const UPDATED = '10 October 2026';

function page(title, body) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} · Axie Dice</title>
<link rel="icon" href="/favicon-axie.png">
<style>
@font-face { font-family: 'Baloo 2'; font-weight: 800; font-display: swap; src: url(/ld-baloo2-800.woff) format('woff'); }
@font-face { font-family: 'Work Sans'; font-weight: 600; font-display: swap; src: url(/ld-worksans-600.woff) format('woff'); }
:root { color-scheme: dark; }
* { box-sizing: border-box; }
body { margin: 0; background: #16220f; color: #FFEBD2; font: 17px/1.65 system-ui, -apple-system, 'Segoe UI', sans-serif; }
main { max-width: 720px; margin: 0 auto; padding: 48px 16px 80px; }
.back { font-family: 'Work Sans', system-ui, sans-serif; font-weight: 600; font-size: 13px; letter-spacing: .14em; text-transform: uppercase; color: #FFC078; text-decoration: none; }
h1 { font-family: 'Baloo 2', sans-serif; font-weight: 800; font-size: 44px; line-height: 1.05; color: #FFF6E6; margin: 20px 0 4px; }
.updated { color: rgba(255,232,206,.6); font-size: 14px; margin: 0 0 32px; }
h2 { font-family: 'Baloo 2', sans-serif; font-weight: 800; font-size: 22px; color: #FFD9B0; margin: 36px 0 8px; }
p, li { color: rgba(255,235,210,.9); }
ul { padding-left: 22px; }
li { margin: 6px 0; }
a { color: #FFC078; }
.card { background: #1f2d15; border: 1px solid #2f4220; border-radius: 14px; padding: 4px 20px; }
footer { margin-top: 48px; padding-top: 20px; border-top: 1px solid #2f4220; font-size: 14px; color: rgba(255,232,206,.6); }
</style>
</head>
<body>
<main>
<a class="back" href="/">&larr; Back to the game</a>
${body}
<footer><a href="/terms">Terms</a> · <a href="/privacy">Privacy</a> · <a href="mailto:${CONTACT}">${CONTACT}</a></footer>
</main>
</body>
</html>`;
}

const TERMS = page('Terms of Use', `
<h1>Terms of Use</h1>
<p class="updated">Last updated ${UPDATED}</p>

<p>Axie Dice is a free browser game made by Liam Nguyen as an entry in Sky Mavis's internal Vibeathon. It is shared with Sky Mavis employees only. By playing it you agree to the points below.</p>

<h2>It is an early build</h2>
<p>Things will change, break and get fixed. We try hard to keep your progress, but if a change ever forces a reset we will say so in the game before it happens.</p>

<h2>Your account</h2>
<ul>
<li>You can play as a guest, or sign in with Google (your Sky Mavis work account or a personal one) to save progress online. The game never asks for or sees your password; sign-in happens on Google's own page.</li>
<li>One account per person. Keep your login to yourself.</li>
</ul>

<h2>Nothing in the game is worth money</h2>
<ul>
<li>Shards, unlocks, dice and every other in-game item have no cash value. They cannot be bought, sold or withdrawn, and they are not tokens or NFTs.</li>
<li>Importing an Axie into the Vault uses its public data to build a die. It does not prove you own that Axie, and it does not move or change the Axie in any way.</li>
</ul>

<h2>Play fair</h2>
<p>Don't attack the servers, automate play to farm progress, or edit saves to get ahead of other players. Accounts that do may be reset or removed.</p>

<h2>Axie artwork and names</h2>
<p>Axie Infinity characters, parts, names and artwork belong to Sky Mavis and are used here as part of the Vibeathon. The game itself is provided as-is, with no promise that it will always be available.</p>

<h2>Questions</h2>
<p>Write to <a href="mailto:${CONTACT}">${CONTACT}</a>.</p>
`);

const PRIVACY = page('Privacy Policy', `
<h1>Privacy Policy</h1>
<p class="updated">Last updated ${UPDATED}</p>

<p>Short version: the game keeps only what it needs to save your progress, it does not show ads, it does not use analytics trackers, and it never sells anything about you.</p>

<h2>If you play as a guest</h2>
<p>Your progress is stored in your own browser (localStorage) and nowhere else. Clearing your browser data deletes it.</p>

<h2>If you sign in with Google</h2>
<p>Google shares these details with the game when you sign in. The game asks only for the basic <i>openid</i>, <i>email</i> and <i>profile</i> permissions:</p>
<div class="card"><ul>
<li><b>Google account ID</b>, the number that identifies you to the game</li>
<li><b>Email address</b>, shown in Settings so you can see which account you are on</li>
<li><b>Display name</b>, shown on the main menu</li>
<li><b>Work domain</b>, only for Google Workspace accounts (for example skymavis.com), used to show a Sky Mavis badge</li>
</ul></div>
<p>Your profile picture is not stored. The game also stores your <b>game progress</b> (shards, unlocks, battle pass, the Axies in your Vault, settings and any run in progress), so you can continue on another device.</p>

<h2>Cookies</h2>
<p>One cookie keeps you signed in, plus a short-lived one during sign-in to protect it against forgery. No advertising or tracking cookies.</p>

<h2>Where it lives</h2>
<p>On Cloudflare (Workers and D1 database), the same service that hosts the game. Cloudflare keeps standard short-term request logs, such as IP address and time, to run and protect the service.</p>

<h2>Importing Axies</h2>
<p>When you scan an Axie ID in the Vault, the game asks Sky Mavis's public Axie service for that Axie's parts. It sends only the Axie ID.</p>

<h2>Who can see it</h2>
<p>Only the game's developer, to run and fix the game. Nothing is sold, rented or shared with advertisers. The game's use of information received from Google follows the <a href="https://developers.google.com/terms/api-services-user-data-policy">Google API Services User Data Policy</a>, including the Limited Use requirements.</p>

<h2>Deleting your data</h2>
<p>Email <a href="mailto:${CONTACT}">${CONTACT}</a> from the address you signed in with and your profile and saves will be deleted within 30 days. Signing out does not delete anything; it only ends the session on that device.</p>

<h2>Changes</h2>
<p>If the game starts storing something new, this page is updated first and the date at the top changes.</p>
`);

export function handleLegal(url) {
  const html = url.pathname === '/terms' ? TERMS : url.pathname === '/privacy' ? PRIVACY : null;
  if (html === null) return null;
  return new Response(html, {
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=300',
      // Same isolation headers as the game, so following a link back to "/" is consistent.
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}

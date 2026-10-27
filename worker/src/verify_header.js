// SR-V leaf module (no imports, so run_core.js can use it without an import cycle).
const MAX_HEADER_BYTES = 2048;
/**
 * Whitelist of the optional `log_header` a client sends with run_close. Returns a clean copy, or null when it is
 * absent / malformed (the close never fails because of it).
 */
export function sanitizeLogHeader(h) {
  try {
    if (!h || typeof h !== 'object' || Array.isArray(h)) return null;
    const out = {};
    if (Array.isArray(h.team_keys)) {
      if (h.team_keys.length > 5 || h.team_keys.some((k) => typeof k !== 'string' || k.length === 0 || k.length > 80)) return null;
      out.team_keys = [...h.team_keys];
    }
    if (typeof h.content_version === 'string' && h.content_version.length <= 40) out.content_version = h.content_version;
    if (Number.isSafeInteger(h.local_secret)) out.local_secret = h.local_secret;
    const lo = h.loadout;
    if (lo && typeof lo === 'object' && !Array.isArray(lo)) {
      const l = {};
      for (const k of ['anchor', 'rules_on', 'core_off']) if (typeof lo[k] === 'boolean') l[k] = lo[k];
      if (typeof lo.boon_id === 'string' && lo.boon_id.length <= 40 && /^[a-z0-9_]*$/.test(lo.boon_id)) l.boon_id = lo.boon_id;
      out.loadout = l;
    }
    return JSON.stringify(out).length <= MAX_HEADER_BYTES ? out : null;
  } catch { return null; }
}


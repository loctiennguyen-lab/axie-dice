-- Run token revocation + account lock (lane S, l1-tasks-S item 8). Apply locally first; staging/production is a
-- deliberate separate step. Existing open runs get token_jti NULL, so their old tokens fail hello until the client
-- calls /api/run/open again (which mints a token with a jti).
ALTER TABLE runs ADD COLUMN token_jti TEXT;
-- Set by an operator (UPDATE players SET locked_at = unixepoch() WHERE id = ?). NULL = not locked.
ALTER TABLE players ADD COLUMN locked_at INTEGER;

-- Depth v4 3.8 / 3.10.9: the server writes the run's depth_stage at creation (from runs_completed, N7) and hands it to the client as
-- header.depth_stage; every later request that carries a stage must match it (stage_mismatch). ADD ONLY: old rows keep NULL = "no stage on
-- record", which openRun answers with 3 (the pre-v4 behaviour). Apply with
--   npx wrangler d1 migrations apply axie-dice-db --local        (staging/production is a separate, deliberate step)
ALTER TABLE runs ADD COLUMN depth_stage INTEGER;

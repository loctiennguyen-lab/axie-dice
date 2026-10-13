-- L1 report (B4). READ-ONLY queries. Run one at a time or the whole file:
--   cd worker && npx wrangler d1 execute axie-dice-db --remote --file=sql/l1_report.sql
-- Client fields come from runs.summary_json (the close summary: a client claim); '$.srv.*' is what the
-- server saw itself (epoch log). Gem charged comes from wallet_ledger (idem_key 'aid:{run_id}:{seq}:{kind}').
-- A closed run has outcome won/lost; abandoned = player left (counts as lost); infra_error = our fault, excluded.

-- 1. Runs per day by state
SELECT date(created_at,'unixepoch') AS day, COUNT(*) AS runs,
       SUM(state='closed') AS closed, SUM(state='abandoned') AS abandoned, SUM(state IN ('open','pending')) AS still_open,
       SUM(state='infra_error') AS infra_error
FROM runs GROUP BY day ORDER BY day DESC;

-- 2. Win rate by Ascension (normal/daily/ranked, finished runs only)
SELECT ascension, COUNT(*) AS runs, SUM(outcome='won') AS won,
       ROUND(100.0*SUM(outcome='won')/COUNT(*),1) AS win_pct,
       ROUND(AVG(battles_done),1) AS avg_battles,
       ROUND(AVG(closed_at-created_at)/60.0,1) AS avg_minutes
FROM runs WHERE mode != 'mission' AND state IN ('closed','abandoned')
GROUP BY ascension ORDER BY ascension;

-- 3. Win rate and length by mode
SELECT mode, json_extract(summary_json,'$.len') AS length, COUNT(*) AS runs, SUM(outcome='won') AS won,
       ROUND(100.0*SUM(outcome='won')/COUNT(*),1) AS win_pct
FROM runs WHERE state IN ('closed','abandoned') GROUP BY mode, length;

-- 4. Where runs end: battles_done distribution (losses only)
SELECT battles_done, COUNT(*) AS lost_runs FROM runs
WHERE outcome='lost' AND state IN ('closed','abandoned') GROUP BY battles_done ORDER BY battles_done;

-- 5. Aid / Continue usage per run (server-seen). R1 = Continue; other ids per aid_prices.js
SELECT j.value AS aid, COUNT(*) AS uses, COUNT(DISTINCT r.run_id) AS runs
FROM runs r, json_each(r.summary_json, '$.srv.aids') j
GROUP BY aid ORDER BY uses DESC;

-- 6. Gem actually charged per Aid (ledger) and total
SELECT substr(reason, 5) AS aid, COUNT(*) AS charges, -SUM(delta) AS gem
FROM wallet_ledger WHERE reason LIKE 'aid:%' AND delta < 0 GROUP BY reason ORDER BY gem DESC;

-- 7. Win rate with vs without Aid/Continue
SELECT (json_array_length(json_extract(summary_json,'$.srv.aids')) > 0) AS used_aid, COUNT(*) AS runs,
       ROUND(100.0*SUM(outcome='won')/COUNT(*),1) AS win_pct
FROM runs WHERE state='closed' AND summary_json IS NOT NULL GROUP BY used_aid;

-- 8. Missions N1-N3: result per tier (stake/payout are Shards, client claim from the close summary)
SELECT json_extract(summary_json,'$.mission.tier') AS tier, COUNT(*) AS runs,
       SUM(json_extract(summary_json,'$.mission.won')) AS won,
       ROUND(100.0*SUM(json_extract(summary_json,'$.mission.won'))/COUNT(*),1) AS win_pct,
       SUM(json_extract(summary_json,'$.mission.stake')) AS stake_total,
       SUM(json_extract(summary_json,'$.mission.payout')) AS payout_total
FROM runs WHERE mode='mission' AND state='closed' GROUP BY tier ORDER BY tier;
-- Missions the player quit (no summary): stake lost, nothing recorded server-side except the run
SELECT COUNT(*) AS mission_abandoned FROM runs WHERE mode='mission' AND state='abandoned';

-- 9. Runs per player (distribution) and top players
SELECT n AS runs_per_player, COUNT(*) AS players FROM (SELECT player_id, COUNT(*) AS n FROM runs WHERE state != 'infra_error' GROUP BY player_id) GROUP BY n ORDER BY n;

-- 10. Newcomer funnel: players by how many runs started / finished a battle / finished a run / came back another day
SELECT COUNT(DISTINCT player_id) AS players_started,
       COUNT(DISTINCT CASE WHEN battles_done >= 1 THEN player_id END) AS fought_1_battle,
       COUNT(DISTINCT CASE WHEN state='closed' THEN player_id END) AS finished_a_run,
       COUNT(DISTINCT CASE WHEN outcome='won' THEN player_id END) AS won_a_run
FROM runs WHERE state != 'infra_error';
SELECT COUNT(*) AS players_back_next_day FROM (
  SELECT player_id FROM runs WHERE state != 'infra_error' GROUP BY player_id
  HAVING COUNT(DISTINCT date(created_at,'unixepoch')) >= 2);

-- 11. Newcomer runs (client flag) vs others
SELECT COALESCE(json_extract(summary_json,'$.newcomer'),0) AS newcomer, COUNT(*) AS runs,
       ROUND(100.0*SUM(outcome='won')/COUNT(*),1) AS win_pct, ROUND(AVG(battles_done),1) AS avg_battles
FROM runs WHERE state='closed' GROUP BY newcomer;

-- 12. Client version / rules version mix
SELECT rules_version, json_extract(summary_json,'$.client') AS client, COUNT(*) AS runs
FROM runs GROUP BY rules_version, client ORDER BY runs DESC;

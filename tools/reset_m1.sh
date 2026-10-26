#!/bin/bash
# M1 reset of the server economy and saves. DRY RUN by default: prints how many rows would go.
#   tools/reset_m1.sh                    dry run on the LOCAL D1
#   tools/reset_m1.sh --remote           dry run on production
#   tools/reset_m1.sh --remote --yes     REALLY deletes (snapshot first: wrangler d1 export axie-dice-db --remote --output=...)
# Run from anywhere; needs wrangler logged in for --remote. Never run before Liam says so.
set -euo pipefail
cd "$(dirname "$0")/../worker"
WHERE="--local"; YES=0
for a in "$@"; do case "$a" in --remote) WHERE="--remote";; --yes) YES=1;; *) echo "unknown flag $a"; exit 2;; esac; done
TABLES="mission_wins mission_escrow leaderboard_scores raid_points raid_daily raid_challenges raid_defense runs saves inventory unlocks echobox_state pass_xp starter_claims wallets wallet_ledger"
Q=""; for t in $TABLES; do Q="$Q${Q:+ UNION ALL }SELECT '$t' AS tbl, COUNT(*) AS n FROM $t"; done
echo "Rows that would be deleted ($WHERE):"
npx wrangler d1 execute axie-dice-db $WHERE --command "$Q"
if [ "$YES" != 1 ]; then echo "DRY RUN only. Add --yes to delete."; exit 0; fi
if [ "$WHERE" = "--remote" ]; then
  echo "This DELETES every player's progress on PRODUCTION (axie-dice-db)."
  read -r -p 'Type exactly "RESET axie-dice-db" to continue: ' ANSWER
  [ "$ANSWER" = "RESET axie-dice-db" ] || { echo "Not confirmed. Nothing changed."; exit 1; }
  SNAP="$(pwd)/../reset-snapshot-$(date -u +%Y%m%d%H%M%S).sql"
  echo "Snapshot first: $SNAP"
  npx wrangler d1 export axie-dice-db --remote --output "$SNAP" || { echo "Snapshot FAILED. Nothing changed."; exit 1; }
  [ -s "$SNAP" ] || { echo "Snapshot is empty. Nothing changed."; exit 1; }
fi
RID="$(date -u +%Y%m%d%H%M%S)"
TMP="$(mktemp)"
sed -e "s/__RESET_ID__/$RID/g" -e "s/__NOW__/$(date -u +%s)/g" scripts/reset_m1.sql > "$TMP"
npx wrangler d1 execute axie-dice-db $WHERE --file "$TMP"
rm -f "$TMP"
echo "Reset done, reset_id=$RID"

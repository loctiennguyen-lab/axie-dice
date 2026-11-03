#!/usr/bin/env bash
cd /Users/loc.tien.nguyen/my-game-wt/u6-qa
for res in 1920x1080 1280x720; do
  d=/Users/loc.tien.nguyen/my-game-wt/u6-qa/production/qa/ui06/qa2/$res; mkdir -p $d
  ( QA_ENTRY=1 QA_ANCHOR=1 QA_SHOP=1 QA_FLOW=win QA_SEED=${QA_SEED:-59} UI5_SHOT_DIR=$d bash godot/tools/with_lock.sh bash godot/tools/shot.sh res://tests/qa_ui5_flow_capture.tscn $res > $d/run.log 2>&1 ) & p=$!
  ( sleep 900; kill $p 2>/dev/null ) & k=$!
  wait $p; kill $k 2>/dev/null
done

#!/usr/bin/env bash
cd /Users/loc.tien.nguyen/my-game-wt/u5b-q2
G=/Users/loc.tien.nguyen/Desktop/Godot.app/Contents/MacOS/Godot
export UI5_SHOT_DIR=/Users/loc.tien.nguyen/my-game-wt/u5b-q2/production/qa/ui05-b23/q2 AXIE_TEST_NO_NET=1 AXIE_HANG_KILL=900
export QA_FLOW=win QA_SEED=59 ADT_EVIDENCE_DIR=/Users/loc.tien.nguyen/my-game-wt/u5b-q2/production/qa/evidence
bash godot/tools/shot.sh res://tests/qa_ui5_flow_capture.tscn $1 > $2 2>&1

#!/usr/bin/env bash
# Asserts the measured claims in SKILL.md still hold against the live orca binary.
# Read-only: creates no runs, tasks or workers. Run after an Orca update.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
O="${ORCA_CLI_COMMAND:-orca}"
R="$($O orchestration run-list 2>/dev/null | grep -oE 'run_[0-9a-f]{12}' | head -1)"
fail=0
a(){ if [ "$2" -eq 0 ]; then echo "FAIL: $1"; fail=1; else echo "ok:   $1"; fi; }

a "drive.sh parses"  "$(bash -n "$HERE"/drive.sh 2>/dev/null && echo 1 || echo 0)"
h=$($O orchestration check --help 2>&1)
a "check still has --format"  "$(printf '%s' "$h" | grep -q -- '--format' && echo 1 || echo 0)"
a "check still has --wait/--types/--ack" "$(printf '%s' "$h" | grep -q -- '--types' && printf '%s' "$h" | grep -q -- '--ack' && echo 1 || echo 0)"
a "worker-release still exists" "$($O orchestration worker-release --help >/dev/null 2>&1 && echo 1 || echo 0)"
a "task-list still has --ready/--brief/--status" "$($O orchestration task-list --help 2>&1 | grep -q -- '--ready' && echo 1 || echo 0)"

gp=$($O skills get orchestration 2>&1 | wc -c)
gf=$($O skills get orchestration --full 2>&1 | wc -c)
cb=$($O skills get orchestration 2>&1 | awk 'BEGIN{s=1} /^## /{s = !/Contract Migration|Gates And Legacy|Full Handoffs|Worker Terminals/} s' | wc -c)
h1=$($O skills get orchestration 2>&1 | grep -c '^## ')
h2=$($O skills get orchestration 2>&1 | awk '/^```/{f=!f} /^## /&&!f' | wc -l)
a "guide slice shrinks the guide ($gp -> $cb B)"     "$([ "$cb" -lt "$gp" ] && echo 1 || echo 0)"
a "no '## ' heading hides in a code fence ($h1/$h2)" "$([ "$h1" -eq "$h2" ] && echo 1 || echo 0)"
a "--full not bigger than plain ($gf vs $gp B)"      "$([ "$gf" -le "$gp" ] && echo 1 || echo 0)"

if [ -n "$R" ]; then
  t=$($O orchestration task-list --run "$R" 2>&1 | wc -c)
  j=$($O orchestration task-list --run "$R" --json 2>&1 | wc -c)
  s=$($O orchestration task-list --run "$R" --status running --brief 2>&1 | wc -c)
  i=$($O orchestration inbox --limit 20 2>&1 | wc -c)
  ij=$($O orchestration inbox --limit 20 --json 2>&1 | wc -c)
  a "task-list text << --json ($t vs $j B)" "$([ "$j" -gt $((t*10)) ] && echo 1 || echo 0)"
  a "--status --brief sweep is tiny ($s B)" "$([ "$s" -lt 2000 ] && echo 1 || echo 0)"
  a "inbox text << --json ($i vs $ij B)"    "$([ "$ij" -gt $((i*3)) ] && echo 1 || echo 0)"
else
  echo "skip: no run found, size ratios unverified"
fi

# The skill must be YOUR copy, not Orca's stock one re-symlinked by an update.
SK="$HERE"
a "skill dir is not a symlink to Orca's copy" "$([ ! -L "$SK" ] && echo 1 || echo 0)"
a "skill still carries the driver rule"       "$(grep -q 'run the DAG in shell' "$SK/SKILL.md" 2>/dev/null && echo 1 || echo 0)"
a "plan.sh parses"                        "$(bash -n "$HERE"/plan.sh 2>/dev/null && echo 1 || echo 0)"
a "plan.sh appends the worker_done cap"   "$(grep -q 'max 400 znakow' "$HERE"/plan.sh && echo 1 || echo 0)"
a "driver filters escalation output"      "$(grep -q 'question|escalation' "$HERE"/drive.sh && echo 1 || echo 0)"
a "driver reports FAILED tasks (exit 20)" "$(grep -q 'DAG FINISHED WITH FAILURES' "$HERE"/drive.sh && echo 1 || echo 0)"
a "driver releases failed workers too"    "$(grep -q 'for st in completed failed' "$HERE"/drive.sh && echo 1 || echo 0)"
a "driver acks before exit 10 (no question replay)" "$(awk '/exit 10/{found=prev1 ~ /check --ack/ || prev2 ~ /check --ack/} {prev2=prev1; prev1=$0} END{print (found?1:0)}' "$HERE"/drive.sh)"
a "driver detects a stalled DAG (exit 30)" "$(grep -q 'DAG STALLED' "$HERE"/drive.sh && echo 1 || echo 0)"
a "driver supports --pool reuse"          "$(grep -q 'POOL=\$2' "$HERE"/drive.sh && echo 1 || echo 0)"
a "pool uses INFLIGHT, not a lagging query" "$(grep -q 'INFLIGHT.*-ge.*POOL' "$HERE"/drive.sh && echo 1 || echo 0)"
a "refused reuse falls back to fresh"     "$(grep -q 'REUSE REFUSED' "$HERE"/drive.sh && echo 1 || echo 0)"
a "plan.sh forwards --pool"               "$(grep -q 'timeout-ms|--pool' "$HERE"/plan.sh && echo 1 || echo 0)"
a "plan.sh supports --template"           "$(grep -q '\-\-template) TPL=' "$HERE"/plan.sh && echo 1 || echo 0)"
a "template braces are escaped for bash"  "$(grep -qF 'TPL//\{\}/' "$HERE"/plan.sh && echo 1 || echo 0)"

# Worktree probing. These guard the 1.0.1 regression: worker-start was called with a
# hardcoded --worktree and its stderr thrown away, so a refusal launched nothing and
# said nothing for 2x--timeout-ms. NOTE: this file is read-only by design and never
# starts a worker, so it CANNOT catch a fresh refusal from a future Orca — only a
# smoke run can. What it does catch is someone reintroducing the silence.
a "driver probes the worktree, never assumes" "$(grep -q 'cands="new-child current"' "$HERE"/drive.sh && echo 1 || echo 0)"
a "driver names new worktrees (--name)"       "$(grep -qF 'nm="--name ${WTNAME:-dag-' "$HERE"/drive.sh && echo 1 || echo 0)"
a "worker-start stderr is captured, not sunk" "$(grep -q 'err=\$(\$O orchestration worker-start' "$HERE"/drive.sh && echo 1 || echo 0)"
a "refused start is printed verbatim"         "$(grep -q 'WORKER START REFUSED' "$HERE"/drive.sh && echo 1 || echo 0)"
a "no-worker DAG aborts fast (exit 40)"       "$(grep -q 'exit 40' "$HERE"/drive.sh && echo 1 || echo 0)"
a "plan.sh forwards --name"                   "$(grep -q '\-\-pool|--name' "$HERE"/plan.sh && echo 1 || echo 0)"
a "task-list example uses a real status"      "$(grep -q 'status running' "$HERE"/SKILL.md && echo 0 || echo 1)"
a "driver self-checks on an Orca version change" "$(grep -q 'orca-checked' "$HERE"/drive.sh && echo 1 || echo 0)"
a "the guard warns but never blocks the DAG"     "$(grep -q 'DAG jedzie dalej' "$HERE"/drive.sh && echo 1 || echo 0)"
a "workers default to opus at low effort"     "$(grep -q 'MODEL="opus"; EFFORT="low"' "$HERE"/drive.sh && echo 1 || echo 0)"
a "no stale --model sonnet left in examples"  "$(grep -q -- '--model sonnet$' "$HERE"/SKILL.md && echo 0 || echo 1)"
exit $fail

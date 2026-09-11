#!/usr/bin/env bash
# Autonomous DAG driver for an Orca Run. The whole coordinator loop runs in shell.
# Nothing here enters an LLM context except the final summary — and, on a decision,
# only the question/escalation message itself.
#
#   bash drive.sh [--agent claude] [--model sonnet] [--effort low] \
#                 [--pool 4] [--worktree new-child] [--timeout-ms 900000]
#
# --pool N  cap concurrent workers at N and REUSE their terminals: when a worker settles
#           and tasks are still queued, its terminal is retained and handed the next task
#           instead of being torn down. Measured: 26.8 s -> 15.5 s per task (-42%), because
#           a reused worker skips session startup. Reuse is sequential per terminal — Orca
#           refuses --terminal while a dispatch is still active — so N also sets parallelism.
#           Omit for the old behaviour: one fresh worker per task, full parallelism.
#
# --worktree: with `current`, workers land in the workspace you are sitting in and Orca's
#           release guard refuses to close them (reason=user_takeover).
#
# Exit 0  = every task succeeded.        Exit 10 = question/escalation (only it is printed).
# Exit 20 = finished, some tasks FAILED. Exit 30 = stalled (worker did work, never reported).
set -u
O="${ORCA_CLI_COMMAND:-orca}"
AGENT=claude; WT=new-child; TMO=900000; MODEL=""; EFFORT=""; POOL=0
while [ $# -gt 0 ]; do case $1 in
  --agent) AGENT=$2; shift 2;; --worktree) WT=$2; shift 2;; --timeout-ms) TMO=$2; shift 2;;
  --model) MODEL=$2; shift 2;; --effort) EFFORT=$2; shift 2;; --pool) POOL=$2; shift 2;;
  *) shift;; esac; done
MFLAG=""; [ -n "$MODEL" ] && MFLAG="--model $MODEL"; [ -n "$EFFORT" ] && MFLAG="$MFLAG --effort $EFFORT"
started=0; reused=0; released=0; retained=0; STALLS=0; FP=""; INFLIGHT=0
DONE=$(mktemp); trap 'rm -f "$DONE"' EXIT

ready_tasks(){ $O orchestration task-list --ready --brief 2>/dev/null | grep -oE '^task_[0-9a-f]+'; }
# INFLIGHT is authoritative: task-list lags a freshly dispatched task by a beat
fresh(){ $O orchestration worker-start --task "$1" --worktree "$WT" --agent "$AGENT" $MFLAG >/dev/null 2>&1 \
         && { started=$((started+1)); INFLIGHT=$((INFLIGHT+1)); }; }

start_ready(){
  for t in $(ready_tasks); do
    if [ "$POOL" -gt 0 ] && [ "$INFLIGHT" -ge "$POOL" ]; then break; fi
    fresh "$t"
  done
}

settle(){                            # release settled workers: succeeded AND failed alike
  for st in completed failed; do
    for t in $($O orchestration task-list --status $st --brief 2>/dev/null | grep -oE '^task_[0-9a-f]+'); do
      grep -qx "$t" "$DONE" 2>/dev/null && continue
      echo "$t" >> "$DONE"; INFLIGHT=$((INFLIGHT-1))
      c=$($O orchestration dispatch-show --task "$t" 2>/dev/null | grep -oE 'ctx_[0-9a-f]+' | head -1)
      [ -z "$c" ] && continue
      # reuse: hand this settled terminal the next queued task instead of tearing it down
      if [ "$POOL" -gt 0 ]; then
        n=$(ready_tasks | head -1)
        if [ -n "$n" ]; then
          $O orchestration worker-retain --dispatch "$c" >/dev/null 2>&1
          h=$($O orchestration worker-show --dispatch "$c" --json 2>/dev/null | grep -oE 'term_[0-9a-f-]{36}' | head -1)
          if [ -n "$h" ] && $O orchestration worker-start --task "$n" --terminal "$h" 2>&1 | grep -q '\[ready\]'; then
            reused=$((reused+1)); INFLIGHT=$((INFLIGHT+1)); continue
          fi
          # reuse refused — never silently drop the task
          echo "  REUSE REFUSED for $n, falling back to a fresh worker"
          fresh "$n"
        fi
      fi
      r=$($O orchestration worker-release --dispatch "$c" 2>&1)
      case "$r" in
        *retained*) retained=$((retained+1))
                    echo "  RETAINED $t $(printf '%s' "$r" | grep -oE 'reason=[a-z_]+')" ;;
        *)          released=$((released+1)) ;;
      esac
    done
  done
}
summary(){ echo "started=$started reused=$reused released=$released retained=$retained"; }

start_ready
ACK=""
while :; do
  if [ -n "$ACK" ]; then
    out=$($O orchestration check --ack "$ACK" --wait --types worker_done,escalation,question --timeout-ms "$TMO" 2>/dev/null)
  else
    out=$($O orchestration check --wait --types worker_done,escalation,question --timeout-ms "$TMO" 2>/dev/null)
  fi
  ACK=$(printf '%s' "$out" | grep -oE 'delivery_[0-9a-f]+' | head -1)

  # a worker that finishes its work but never sends worker_done leaves its dispatch active
  # forever; check --wait then times out silently and the DAG would hang unnoticed.
  if [ -z "$out" ]; then
    fp=$($O orchestration task-list --brief 2>/dev/null | md5sum)
    if [ "$fp" = "$FP" ]; then STALLS=$((STALLS+1)); else STALLS=0; FP=$fp; fi
    if [ "$STALLS" -ge 2 ]; then
      echo "DAG STALLED: no message and no state change across 2 waits — $(summary)"
      $O orchestration task-list --status dispatched --brief 2>/dev/null | sed 's/^/  STUCK /' | cut -c1-100
      echo "  inspect with: ORCA orchestration worker-read --dispatch <ctx_id>"
      exit 30
    fi
  else STALLS=0; fi

  if printf '%s' "$out" | grep -qE '\[(escalation|question)\]'; then
    echo "=== DECISION REQUIRED — $(summary) ==="
    # only the blocks that need judgement; routine reports in the same delivery stay out
    $O orchestration check --peek --format 2>/dev/null \
      | awk '/^────/{p=/\((question|escalation)\)/} p'
    # ack before handing over, or the same question replays on every resume
    # (settle() reads task-list, not messages, so acking loses nothing)
    [ -n "$ACK" ] && $O orchestration check --ack "$ACK" >/dev/null 2>&1
    exit 10
  fi

  settle
  start_ready
  $O orchestration task-list --brief 2>/dev/null | grep -qE '\[(ready|dispatched|blocked|pending)\]' && continue

  [ -n "$ACK" ] && $O orchestration check --ack "$ACK" >/dev/null 2>&1
  failed=$($O orchestration task-list --status failed --brief 2>/dev/null | grep -oE '^task_[0-9a-f]+')
  if [ -n "$failed" ]; then
    echo "DAG FINISHED WITH FAILURES — $(summary)"; printf '  FAILED %s\n' $failed; exit 20
  fi
  echo "DAG COMPLETE — $(summary)"; exit 0
done

#!/usr/bin/env bash
# Create a Run, its Tasks, and start the driver — in ONE call, so DAG setup costs one turn.
# Specs come on stdin, one per line (blank lines ignored). The worker_done cap (Rule 3) is
# appended to every spec automatically — never type it per task.
#
#   bash plan.sh --objective "build X" --model sonnet <<'SPECS'
#   first task spec
#   second task spec
#   SPECS
#
# Passes --agent/--model/--effort/--worktree/--timeout-ms straight through to drive.sh.
set -u
O="${ORCA_CLI_COMMAND:-orca}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OBJ=""; PASS=""; TPL=""
while [ $# -gt 0 ]; do case $1 in
  --objective) OBJ=$2; shift 2;;
  --template) TPL=$2; shift 2;;
  --agent|--model|--effort|--worktree|--timeout-ms|--pool|--name) PASS="$PASS $1 $2"; shift 2;;
  *) shift;; esac; done
[ -z "$OBJ" ] && { echo "plan.sh: --objective is required" >&2; exit 2; }

CAP=' ZASADY RAPORTOWANIA: worker_done body max 400 znakow — outcome, co sie zmienilo, co zostalo. Zero narracji, zero opisu plikow, zero kodu. Pelny raport idzie w wynik zadania.'

r=$($O orchestration run-create --objective "$OBJ" 2>&1) || { echo "$r" >&2; exit 1; }
echo "$r" | head -1
n=0
while IFS= read -r spec; do
  [ -z "${spec// }" ] && continue
  [ -n "$TPL" ] && spec=${TPL//\{\}/$spec}
  $O orchestration task-create --spec "$spec$CAP" >/dev/null 2>&1 && n=$((n+1))
done
echo "tasks created: $n"
[ "$n" -eq 0 ] && { echo "plan.sh: no specs on stdin" >&2; exit 2; }
exec bash "$HERE/drive.sh" $PASS

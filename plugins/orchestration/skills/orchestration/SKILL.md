---
name: orchestration
description: >-
  Supervised Orca multi-agent coordination: threaded messages, blocking
  ask/reply, task dispatch, worker_done/escalation waits, task DAGs, decision
  gates, coordinator loops, decomposing work across agents. Use the orca-cli
  skill instead for ownership handoffs ("hand off", "handoff", "handover",
  "give this to another agent", "another worktree"), terminal control, shell
  commands, worktree management, and Orca's embedded browser — unless asked to
  supervise, monitor, or coordinate a DAG. Use Computer Use only for
  OS/window-level control outside Orca: external browser windows, desktop UI,
  focus, menus, dialogs, coordinates, screenshots. Load this skill BEFORE running
  any `orca orchestration` command: its rules are measured on live runs and
  override the binary's own guide, which puts --json on every example and costs
  93x more on task-list.
---

# Orca Orchestration — the LLM is not the loop

All numbers below were measured on live Orca runs, not estimated. They override the
binary's own guide wherever they differ — that guide puts `--json` on every example,
which is a context bomb.

Coordination requires real Orca runtime state; never substitute a non-Orca subagent tool.

## Resolve the CLI once

`ORCA_CLI_COMMAND` if set → else `orca-dev` in a checkout exposing `ORCA_DEV_REPO_ROOT`
→ else `orca-ide` on Linux outside an Orca terminal (bare `orca` there is the GNOME
screen reader and starts speech) → else `orca`. `ORCA` below is that executable,
substituted literally. If it cannot run, report its exact error and stop.

## Rule 1 — run the DAG in shell, not in your context

Set up and run the whole graph in one call — specs on stdin, one per line. The
`worker_done` cap from Rule 3 is appended to every spec by the script, so never type it
per task:

```text
bash ${CLAUDE_PLUGIN_ROOT}/skills/orchestration/plan.sh --objective "<goal>" --model sonnet <<'SPECS'
first task spec
second task spec
SPECS
```

It creates the Run and Tasks, then execs `drive.sh`, which launches every ready task,
blocks on `check --wait`, releases settled workers (succeeded *and* failed), advances the
graph, and repeats. Re-enter with `drive.sh` alone after answering a question.

**Exit 0** = every task succeeded. **Exit 10** = a question/escalation needs judgement —
only that message is printed, routine reports sharing the delivery stay out of your
context. **Exit 20** = the DAG finished but tasks FAILED, and they are listed: a failure
is never reported as success.

Measured on a 54-task / 61-`worker_done` run: **~176 coordinator turns → 4**, and
**56,006 B → 3,644 B** into context (−93.5%). Turn count is the real prize, because every
turn re-reads the whole conversation: ~10.6M token-reads → ~80k, **~132×**. Prompt caching
discounts both sides equally, so the ratio stands.

Supervise by hand only when the user asks to watch it live. Then use Rules 2-5.
## Rule 2 — nothing needs `--json`. Measured on a live run:

| command | text | `--json` | waste |
|---|---|---|---|
| `task-create` | **34 B** | 1,048 B | 31× |
| `worker-start` | **54 B** | 1,605 B | 30× |
| `check` (carries `delivery_id`) | **91-296 B** | 1,151-4,515 B | 10-23× |
| `check --format` (adds bodies + `[Payload]`) | 3,554 B | 8,137 B | 2.3× |
| `task-list` (53 tasks) | 4,553 B | **424,397 B** | **93×** |
| `dispatch-show` | 52 B | 1,216 B | 23× |
| `run-create` | 106 B | ~650 B | 6× |

Plain `check` prints `Delivery delivery_…` — the `--ack` id is in the text form, so the
last excuse for `--json` is gone. `--format` adds bodies and the
`[Payload: {"taskId","dispatchId","outcome"}]` line; use it when you need the result,
plain `check` when you only need to know what finished.

## Rule 3 — cap what workers write back

`worker_done` bodies averaged **1,689 chars** — **47.7% of all actionable payload**.
The full report is already in the Task's `result` field, retrievable on demand. Put this
in every `task-create --spec`:

```text
worker_done body: max 400 chars. Outcome (done/blocked), what changed, what is left.
No narrative, no restating the task, no code. Full detail goes in the task result.
```

Saves **81,177 B (~20k tokens)** on a run that size — more than every JSON flag combined.

Validated A/B on real work (two identical 4-task builds of a chat site, 4 Claude
workers each): the spec **does** override Orca's preamble, which otherwise asks for a
"3-sentence executive summary". Bodies went 688 -> 344 chars average, 952 -> 391 max,
**-49.9% body bytes / -30.7% message bytes**, with both arms passing their smoke tests
and arm B producing one more file. Cheaper reports did not mean worse work.

## Rule 4 — always filter

```text
ORCA orchestration task-list --status dispatched --brief      # 94 B
ORCA orchestration check --wait --types worker_done,escalation,question --timeout-ms 900000
```

Unfiltered `task-list --json` is 424,397 B — **4,515×** the filtered sweep. `--types`
dropped **146 of 210 messages (69% heartbeats, 102,023 B)** on the measured run.
`--wait` blocks; it is not a poll. Timeout or `{count:0}` is a checkpoint, not a failure —
workers routinely run 15-60 min. Never kill a quiet worker.

## Rule 5 — do not load the binary's guide, and never reload it on error

This file carries the loop. Orca's error text says "run: `skills get orchestration --full`";
obeying it costs 44,348 B (~11k tokens) **per error**, and `--full` is byte-identical to
plain. Load it only for an unknown flag, a contract-migration message, a decision gate, or
remote `--on` placement — then to a file, sliced:

```text
ORCA skills get orchestration > "$TMPDIR/orca-guide.md"
awk 'BEGIN{s=1} /^## /{s = !/Contract Migration|Gates And Legacy|Full Handoffs|Worker Terminals/} s' "$TMPDIR/orca-guide.md"
```

## Orca updates verify themselves

`drive.sh` remembers the `orca --version` it last validated against. When the binary
changes, the next run silently re-runs `check.sh` and prints **only what broke** — no
flag, no ritual, ~6 s once per Orca version, 0.2 s after that.

This guards the *quiet* drift: if Orca stopped saving bytes on text output, the DAG would
keep working while every number in this file turned into a lie. Loud breakage needs no
guard — a refused `worker-start` prints its own reason and exits 40 on the spot.

Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/orchestration/check.sh` by hand only when you want
the full green list.

## Known: what the spec cannot reach

Orca injects a **4,672 B preamble into every worker** (`dispatch-show --task <id> --preamble`).
It is a fixed per-worker cost the coordinator cannot trim.

**Heartbeats are not a timer and are not worth optimizing.** The preamble says "send a
heartbeat every 5 minutes", but that is not what workers do. Measured on a real 65-worker
run: 146 heartbeats total = **2.2 per worker**, with intervals scattered from 0.7 to 16.6
minutes (median 7). They track phase changes (implementing / investigating / reviewing),
not elapsed time. A controlled A/B with two workers running **467 s and 488 s** — both past
the 5-minute threshold, one told to suppress heartbeats and one not — produced **zero
heartbeats in both arms**, so the suppression instruction could not be validated: there was
nothing to suppress. Coordinator-side the cost is already zero, because
`--types worker_done,escalation,question` filters heartbeats out entirely (Rule 4). What
remains is ~2.2 extra turns per worker. Do not spend spec text on it.

## Rule 6 — reuse workers on short tasks (`--pool N`)

A fresh worker pays full session startup — system prompt, CLAUDE.md, tool definitions, plus
Orca's 4,672 B preamble — before it touches the task. Measured sequentially on identical
tiny tasks: **fresh 26.8 s vs reused 15.5 s per task (−42%)**; startup is ~11 s, over half
the wall time of a small task. In the driver at `--pool 2` over 4 tasks: 82 s → **66 s**,
`started=2 reused=2`, 4/4 self-checks passing.

```text
bash ${CLAUDE_PLUGIN_ROOT}/skills/orchestration/plan.sh --objective "<goal>" --model sonnet --pool 4 <<'SPECS'
...
SPECS
```

**The trade-off is real.** Orca refuses `worker-start --terminal` while a dispatch is still
active (`already has an active dispatch`), so a reused terminal runs its tasks strictly in
sequence — `--pool N` therefore sets parallelism too. Use it when tasks are short (startup
dominates); omit it when tasks run minutes each (parallelism is worth more than 11 s).
Reuse that is refused falls back to a fresh worker and says so — a task is never dropped.

**Reuse depends on workers settling.** A worker that does the work and answers in prose
instead of sending `worker_done` leaves its dispatch active forever, blocking the whole
chain on that terminal. Seen once in testing; Rule 1's `exit 30` catches it.

## Known: the preamble cannot be trimmed (measured, dead end)

Orca injects a **4,672 B preamble into every worker**. It is not configurable: there is no
`orca config`, the preamble module reads no env var and has no conditional flag, no user
file overrides it, and no `worker-start` / `dispatch` flag touches its content —
`dispatch --return-preamble` only *prints* what would be injected. Substituting a shorter
one means `dispatch --inject`, which by Orca's own guide creates an **unsupervised** worker
(no `worker_dispatches` row, `worker-release` returns `no_owned_resource`) — losing the
`worker_done` authority and settle tracking the driver runs on. Treat the preamble as a
fixed per-worker cost; `--pool` (Rule 6) is the only way to pay it fewer times.

## Rule 7 — templates for homogeneous DAGs (`--template`)

When N tasks differ by one word (five page sections, ten endpoints, one module per name),
write the spec once and feed the varying part on stdin. Every `{}` is replaced:

```text
bash ${CLAUDE_PLUGIN_ROOT}/skills/orchestration/plan.sh --objective "<goal>" --model sonnet --pool 4 \
  --template 'W katalogu src stworz {}.js: funkcja {}(x) z assert self-check, uruchom.' <<'ITEMS'
inc
dec
dbl
ITEMS
```

Spec authoring drops from N × full spec to one spec + N words — on a 54-task homogeneous
DAG that is roughly 6.5 KB of your own output tokens down to ~0.3 KB. Verified end to end:
3 tasks, 3/3 self-checks passing, `started=2 reused=1` at `--pool 2`.

**A template cannot save you from a wrong spec.** The driver reports mechanical failures
(exit 10/20/30) but a DAG whose specs are nonsense still exits 0 — an earlier run of this
very feature produced a file literally named `}.js` and reported `DAG COMPLETE`. Verify the
artifacts, not the summary.

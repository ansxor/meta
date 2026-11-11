# Configuration harness (Pi extension)

`.pi/extensions/config-harness/` is a project-local [Pi](https://pi.dev) extension
for long-lived sessions in this repository. Each request starts from live files,
a compact notes file, and recent diffs instead of replaying the whole transcript.

Load it by starting Pi in this repository. Project `.pi/` resources require
project trust; accept the trust prompt, start with `pi --approve`, or use
`/trust` first. `pi --no-approve` ignores it. Auto-discovery of
`.pi/extensions/<name>/index.ts` is documented in Pi's `docs/configuration.md`
and `docs/extensions.md` (Pi 1.4.0).

## What a request carries

The extension rewrites the `context` event for every provider request. The
order is stable to least-stable:

```
<config-harness-context>
  <vital-files>      flake.nix, host, common module, home entry points, README
  <compaction>       model-maintained notes
  <diff>             up to 3 recent human/agent shadow diffs
  <last-exchange>    verbatim previous user prompt + final assistant text
  <harness-state>    last check, side effects
</config-harness-context>
<current run>        this request's messages and tool results, unchanged
```

Vital files are re-read from disk before every model call. `flake.lock` and
`docs/*` are excluded by policy; the total is capped at 60 KB.

## Notes

The model owns `.pi/compaction.md` and edits it in place. It is capped at 4 KB.
The harness appends a small state appendix (last check, side effects, blocked
request) and replaces only its own previous appendix. If the model edits inside
that appendix, the edited text is preserved as notes and a fresh appendix is
appended. When a request changes files but leaves the notes untouched, the
harness sends one `continue: true` nudge; a request is never nudged twice.

At `agent_before_settle` the harness writes a real Pi `compaction` entry whose
summary is the notes, and keeps the final assistant message as
`firstKeptEntryId` so print mode still has an answer. The `context` event still
rebuilds fresh files/diffs for the next request; those blocks are not persisted
to the session.

## Shadow diffs and rollback

`.pi/shadow.git` is a separate bare git directory with `--work-tree=.`. It
never touches real history. A start snapshot and an end snapshot are committed
per request:

- `human`: previous end snapshot → current start snapshot (hand edits between
  requests)
- `agent`: current start → end (model edits during the request)
- `agent-rolled-back`: failed work saved during `need_input`

Guard snapshots after mutating tool calls distinguish agent state from a
concurrent hand edit. `need_input({ why, needs })` saves the failed tree to
`refs/need-input/<timestamp>`, restores changed files to the start snapshot,
leaves files that changed outside the agent in place, prints the reason and
request, and records the failure/ref in the notes. Irreversible side effects
(an approved activation) are reported with a reversal hint.

## Activation gate

Pi's bash tool has no TTY, and `scripts/switch.sh` runs `sudo nixos-rebuild`.
The extension intercepts `tool_call` for:

- `./scripts/switch.sh`
- `nixos-rebuild switch|test|boot` (including with `--flake`)
- `switch-to-configuration`

It opens one `zenity --question` dialog showing the command and a shadow diff
summary, with a timeout. Deny, timeout, close, missing `zenity`, no graphical
session (`DISPLAY`/`WAYLAND_DISPLAY` both unset), or a missing `sudo` blocks
the call. On approval it rewrites the command to put a `sudo` shim first on
`PATH` and sets
`SUDO_ASKPASS` to a helper that runs `zenity --password`; the shim execs the
real sudo with `-A`. The password goes only from Zenity to sudo; it is never
read, logged, stored in notes, or added to shadow snapshots. `zenity` is
declared in `hosts/crystalheart/home/packages/desktop.nix`, so activation works after the
next switch. On a system where it is not installed yet (including the first
activation), start Pi inside `nix shell nixpkgs#zenity` or install it manually;
otherwise the gate fails closed.

## Raw history

`recall({ query?, limit? })` reads the session's append-only entries, including
messages hidden by compaction, and returns matching snippets. The notes are the
working state; raw history is the fallback for details.

## Configuration

`.pi/config-harness.json` holds defaults and may be edited by hand. It is not
model-maintained; the model is instructed not to change it. The hard secret
deny-list (`*.env`, `*.key` and `*.age`) is also compiled into the extension, so it cannot be removed by config. Denied
paths are excluded from both injected context and shadow snapshots.

```json
{
  "vitalFiles": ["flake.nix", "hosts/crystalheart/default.nix", "modules/nixos/common.nix", "hosts/crystalheart/home/default.nix", "hosts/crystalheart/home/dotfiles.nix", "README.md"],
  "notesFile": ".pi/compaction.md",
  "notesMaxBytes": 4096,
  "diffCount": 3,
  "check": { "command": "./scripts/check.sh", "enabled": true },
  "switch": { "timeoutMs": 60000 }
}
```

The optional check command runs on a completed request's final settle (not
after an abort, and not on the nudge pass), with a timeout. Its result appears
in context and in the notes appendix. Test copies should set `check.enabled`
to `false`.

## Spike findings (Pi 1.4.0)

Run against a throwaway copy of the repository with `pi --print --approve`,
`--provider xiaomi --model mimo-v2.6-flash`, stubbed `zenity`/`sudo`.

1. **Compaction at `agent_before_settle`** — A `compaction` draft is accepted,
   appended with `fromHook: true`, and committed after the boundary. With
   `firstKeptEntryId: null` the entry keeps no earlier messages (the stored id
   becomes its own). With `firstKeptEntryId` set to the final assistant entry,
   the next session projection is the compaction summary + that assistant
   message; `--print` correctly emits the assistant text. Observed.
2. **Auto-compaction vs. `context`** — Threshold checks use the canonical
   session projection, not the rewritten request. Because each request ends in
   a small notes compaction, the canonical projection stays small. A very long
   single run can still trigger Pi's own compaction; the notes file is read
   independently, so the injected context survives. Not exercised with an
   actual threshold crossing; based on Pi source (`agent-session.ts`,
   `_compactBeforeNextAssistantResponse`) and the observed settle ordering.
3. **Stale tool results in a run** — `context` runs before every provider
   request, while the current run's tool calls/results are preserved. Fresh
   vital files appear at the top of each request, so a file read earlier in the
   same run may be stale; the injected block is the authoritative copy.
   Observed that `context` fires each request; a dedicated stale-read test was
   not run.

## Verification

The end-to-end run used a throwaway copy of this repository, with the extension
loaded by Pi project discovery from `.pi/extensions/config-harness` and a
temporary agent directory containing only credentials. It exercised: a hand edit showing as a
human diff, an agent edit showing as an agent diff, `need_input` deleting the
created file and saving `refs/need-input/...`, an approved gate with stubbed
`zenity`/`sudo` (including `SUDO_ASKPASS`), a denied gate with no sudo call,
and the missing-`zenity` denial. A concurrent hand edit during a run was left
in place and reported as a conflict; a clean gate test found no password value
in notes, session, or shadow history. Real git history stayed at its single
baseline commit while shadow commits recorded the changes. In print mode the
blocked report is in the tool result/session, not in the final text stream; the
harness also calls `ctx.ui.notify` for dialog-capable clients.

---
type: meta
updated: {{TODAY}}
---

# Automation

What runs by itself, what runs when you invoke it, and what is only a convention
that Claude follows because it is told to. The distinction matters: two of the
four things below will not happen unless a human or a scheduler makes them
happen, and mistaking a convention for a guarantee is how a vault rots while
looking healthy.

## 1. Scheduled: deterministic drift detection

- **What:** `50-Meta/scripts/drift-scan.ps1`
- **When:** weekly, Monday 09:00, via the Windows Task Scheduler task
  `PAI-DriftScan`. Registered once by `50-Meta/scripts/register-drift-task.ps1`.
  `StartWhenAvailable` is set, so a missed run catches up at next boot.
- **Does:** checks every note in `10-Projects` against its real repo, finds repos
  with no note, writes a dated report to `00-Inbox`, commits it, pushes it.
- **Does NOT:** rewrite note content. Ever. It only detects.
- **No LLM, no interactive auth.** That is what makes it safe to schedule.

If the sync fails, the script says so on stdout and exits non-zero. It used to
print "Committed and pushed." unconditionally, because native commands do not
throw in PowerShell and `$LASTEXITCODE` was never read. That is worth stating
plainly: for a while, the mechanism whose entire job was to catch drift was
silently failing to report its own. **A check that cannot fail is not a check.**

**Verify the task is real, do not assume it.** Registration is not execution. Run
`schtasks /Query /TN PAI-DriftScan /FO LIST` and confirm `Last Result` is `0` and
`Last Run Time` is not `N/A`. A task that has been registered but has never fired
looks identical to a working one in every place except that field.

## 2. Hook: prose lint (PostToolUse)

- **What:** `~/.claude/hooks/lint-ai-tells.mjs`, wired in `~/.claude/settings.json`.
- **When:** after every `Write` / `Edit` / `MultiEdit` on a prose file.
- **Does:** flags em dashes and en dashes as errors, plus a blocklist of tell
  vocabulary as advisories. Masks code blocks, inline code, URLs, and CLI flags
  first, so `Unlock-ADAccount` and `--elevate` do not trip it.
- **Never blocks.** It always exits 0 and reports as context.

## 3. Hook: session context (SessionStart)

- **What:** `50-Meta/scripts/session-context.ps1`, wired in `~/.claude/settings.json`.
- **When:** every Claude Code session start.
- **Does:** reads the session's working directory, finds the project note whose
  `repo:` frontmatter is the longest path prefix of it, and injects that note as
  context along with the capture-at-source instruction. If no repo matches but the
  session is inside the workspace, it injects a compact project index instead.
  Outside the workspace, it stays silent.
- **Why longest-prefix and not name matching:** an earlier version matched
  directory names against note filenames, which injected the *wrong note* whenever
  one repo contained a subdirectory named after another. It then told Claude to
  write its decisions into that wrong note. Silent corruption of the durable
  record is the worst failure this system can have.

**Hook changes take effect next session.** Editing the hook definition in
`settings.json` does nothing to the session you are currently in. Editing the
*script* the hook invokes does take effect immediately, because it is re-read on
each call. This trips everyone once.

## 4. Convention only: capture-at-source

- **What:** Claude appends dated decisions to a project note before a session ends.
- **Enforced by:** nothing. It is an instruction in `CLAUDE.md`, re-injected into
  every tracked-repo session by hook 3.
- **Therefore:** it fires when the model complies, which is most of the time and
  not all of the time.

Be honest with yourself about this one. In the reference implementation this
mechanism ran for a full phase and fired **approximately once**: 31 of 33 project
notes still carried a byte-identical seed decision log, and the drift scanner
happily reported them all as `ok`, because a stub is structurally indistinguishable
from a rich note. The scanner checks that a note exists and matches its repo. It
cannot check that the note says anything.

That gap is not fixable by more automation. It is the part of the system that
depends on you.

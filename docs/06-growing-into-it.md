# 06 Growing into it

This kit is the lean core on purpose. A vault that does less but stays accurate beats
one with many parts you do not understand. Here is what exists beyond the starter, so
you know what to grow into once the basics are habit.

Do not add these in your first month.

## Natural next steps

**A claims layer.** Today the scanner only checks that things exist and whether a
project has moved on. A claims layer lets a note state a checkable fact ("the test
suite has 208 tests") that a script re-measures against the real project, so the
note can be proven wrong automatically. It is the next level of "a check that can
fail". It needs a small parsing module and a convention for writing claims in notes.

**A session-end warning.** A hook that runs when a Claude session ends, looks at the
vault's git state, and shows a Windows notification if there are uncommitted notes
or unpushed commits. It detects only; it never commits for you.

**A catch-up skill.** A Claude skill you invoke when you return to a project after
time away. It reads the project note, compares it with the live git history, and
briefs you on where you left off, what is half done and what to do next.

**A wrap-up skill.** A skill you invoke when ending a day. It commits and pushes
unsaved work in your repos and makes sure the vault notes are captured.

**Your own skills.** A Claude skill is a folder with a `SKILL.md` of instructions.
`pai-drift-check` in `~/.claude/skills/` is a worked example. When you catch
yourself giving Claude the same long set of instructions twice, that is a skill.

**Working agreements.** A single note in `50-Meta` listing your portable process
habits across all projects ("never edit files while a test suite is running",
"findings are leads, not facts"). Grow it from real mistakes, one line at a time,
each with the reason. Keep a pointer to it from your global
`~/.claude/CLAUDE.md` so every session sees it.

## Signs you are ready for more

- You open the weekly report and act on it without having to relearn what it means.
- Your notes are mostly accurate when you read them.
- You have caught Claude using a note to avoid an old mistake at least once.

## Signs to slow down

- Reports pile up unread. Fix the habit before adding anything.
- You have notes you no longer believe. Run `pai-drift-check` and repair or archive
  them.
- You cannot explain what a script does. Read it, or remove it.

## A rule for every addition

Whatever you add, make it fail loudly. An automatic check that prints "all clear"
while broken is worse than having no check, because it earns trust it has not
earned. Prove each new part works by running it, and by making it fail once on
purpose to see that it says so.

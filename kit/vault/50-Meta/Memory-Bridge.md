---
type: meta
updated: {{TODAY}}
---

# Memory Bridge

How this vault and Claude Code's `.claude` memory system divide ownership.

## The invariant: one fact, one home

Content lives in **exactly one** place. The vault holds the content. Memory holds
at most a one-line pointer to it.

Duplicating a fact into both is the failure mode this rule exists to prevent.
Two copies drift apart, and then neither is trustworthy: you cannot tell which
one is current without checking the source, at which point the copies were worse
than useless, because they cost you the illusion of knowing.

| Holds | Owner |
|---|---|
| Project state, decisions, open threads | **The vault** (`10-Projects`) |
| Durable cross-project lessons | **The vault** (`30-Knowledge`) |
| Who you are, how you work | **The vault** (`50-Meta`) |
| A pointer saying "the vault is at `{{VAULT}}`" | **Memory** |

## The catch worth knowing

Claude Code keys memory by the **session's working directory** slug, not by the
vault's location. A session started in `{{WORKSPACE_ROOT}}\SomeRepo` loads memory
from a different directory than one started in `{{WORKSPACE_ROOT}}`.

That means a memory file written in one repo's session is invisible from another
repo's session. Memory cannot carry a cross-project fact. This is not a bug you
can configure around; it is how the system is keyed.

**The consequence:** the pointer to this vault must live somewhere that loads
everywhere, which means your **global** `CLAUDE.md` (at `~/.claude/CLAUDE.md`),
not a per-project memory file. Put it there. The SessionStart hook handles the
rest by injecting the matching project note directly.

## Promotion

A lesson starts life in a project note. When it proves reusable somewhere else,
it moves to `30-Knowledge` as its own atomic note, and the project note keeps a
one-line pointer. That is promotion, and it is the only way `30-Knowledge` should
ever fill.

# PAI-StarterKit

A starter kit for a **PAI vault** (Personal AI Infrastructure): a folder of plain
notes that gives [Claude Code](https://claude.com/claude-code) a memory.

Normally every Claude Code session starts blank. You re-explain the project, what
you decided last week, and how you like to work. With a PAI vault, Claude opens
each session already knowing the project, its current state, and your standing
preferences, and it writes down what it learned before it leaves.

**New to all of this? Start with [docs/00-start-here.md](docs/00-start-here.md).**
It assumes nothing beyond having Claude Code installed.

**Windows only.** The scripts are PowerShell and the scheduler is Windows Task
Scheduler. Tested on Windows 11. Mac and Linux are not supported yet.

## What you get

```
kit/
  bootstrap.ps1       builds your vault and wires it up, in one command
  vault/              the starting folder tree, rules, templates and scripts
  skill-template/     the pai-drift-check skill (Claude's "check my notes" routine)
  hooks/              an optional prose lint hook
docs/                 the guide, written for beginners
examples/             a filled-in sample project note and knowledge note
```

## The short version

1. Install the [prerequisites](docs/01-prerequisites.md).
2. Run one command:
   ```powershell
   pwsh -File .\kit\bootstrap.ps1 -VaultPath C:\GitRepos\MyVault -WorkspaceRoot C:\GitRepos
   ```
3. Paste the block it prints into `~/.claude/settings.json`, then restart Claude Code.
4. Open Obsidian on the new vault, fill in `About-Me`, and add your first project.

The full, slow, step-by-step version is [docs/02-first-hour.md](docs/02-first-hour.md).

## The guide

| Read | When |
|------|------|
| [00 Start here](docs/00-start-here.md) | You want to know what this is and whether you want it |
| [01 Prerequisites](docs/01-prerequisites.md) | Before you install anything |
| [02 Your first hour](docs/02-first-hour.md) | Setting it up, with the output you should see |
| [03 Daily use](docs/03-daily-use.md) | After it works: the habits that make it pay off |
| [04 How it works](docs/04-how-it-works.md) | You want to understand the three moving parts |
| [05 Make it yours](docs/05-make-it-yours.md) | Customizing rules, areas and style |
| [06 Growing into it](docs/06-growing-into-it.md) | You outgrew the starter |
| [07 Working in Obsidian](docs/07-working-in-obsidian.md) | Right after your first hour: how to live in the vault |
| [Glossary](docs/glossary.md) | A word in the guide is new to you |
| [Troubleshooting](docs/troubleshooting.md) | Something did not work |

## The one rule the design rests on

**A check that cannot fail is not a check.** Every automatic part of this kit is
built to fail loudly. If a scheduled scan cannot finish, it exits with an error
instead of printing "all good". If you extend the kit, keep that property.

## License

MIT. See [LICENSE](LICENSE). This is an independent community project and is not
affiliated with or endorsed by Anthropic.

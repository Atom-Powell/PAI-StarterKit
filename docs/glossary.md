# Glossary

**Branch.** A named line of history in git. This kit uses one, called `main`.

**Capture.** Writing down a decision or a change of state in the right note, soon
after it happens. The vault rules ask Claude to capture at the end of a session.

**Claude Code.** Anthropic's command-line coding assistant. The thing you start with
the `claude` command.

**Commit.** A saved snapshot in git, with a message. Obsidian Git makes one every
ten minutes if anything changed.

**Drift.** When a note says something that is no longer true. The note has drifted
away from reality.

**Drift report.** The weekly file in `00-Inbox` listing notes that look stale,
broken, malformed or missing.

**Frontmatter.** The block of `key: value` lines between two `---` lines at the top
of a note. Scripts read it, so its format matters.

**Git.** The tool that records the history of a folder and syncs it to places like
GitHub.

**GitHub.** A website that stores git folders ("repositories") online.

**Hook.** A small script Claude Code runs automatically when something happens, for
example when a session starts. Configured in `settings.json`.

**Knowledge note.** A note in `30-Knowledge` holding one lasting idea.

**Markdown.** The simple text format the notes use. `#` makes a heading, `-` makes a
bullet, `[[Name]]` makes a link to another note.

**Obsidian.** A free app for reading and editing a folder of markdown notes. It
shows links between notes. Your vault is "opened" in it.

**Plugin.** An add-on for Obsidian. This kit uses three: Git, Dataview, Templater.

**PowerShell.** The Windows command-line shell and scripting language. The kit's
scripts are written in it.

**Remote.** The online copy of a git folder, usually on GitHub. `origin` is the usual
name for your main one.

**Repo (repository).** A project folder tracked by git.

**Session.** One run of Claude Code, from the moment you type `claude` until you
close it.

**Skill.** A folder of instructions Claude loads when relevant. `pai-drift-check` is
one.

**Stale.** A note whose project has changed since you last confirmed the note.

**Task Scheduler.** The Windows feature that runs programs on a schedule.

**Templater.** An Obsidian plugin that fills in new notes from `_templates`.

**Token.** In the setup script, a placeholder like `{{VAULT}}` that the script swaps
for a real value. Not the same as an AI token.

**Vault.** The folder of notes. Also an Obsidian term for the folder you open.

**Wikilink.** A link written `[[Note Name]]`.

**Workspace.** The parent folder holding all your projects, such as `C:\GitRepos`.

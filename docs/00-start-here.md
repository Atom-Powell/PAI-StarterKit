# 00 Start here

## The problem this solves

Claude Code is smart, but every session starts with a blank head. Yesterday you
spent an hour deciding how your project should handle logins. Today you open a new
session and Claude has no idea. You explain it again, or it guesses, or it
cheerfully undoes yesterday's decision.

## The idea

Keep your project knowledge in a folder of plain text notes. Then arrange for Claude
to read the right note at the start of every session, and to write down what it
learned at the end. That folder is a **vault**, and the whole arrangement is called
a **PAI vault** (Personal AI Infrastructure). It is not a product or a service.
It is a folder, a few small scripts, and some habits.

## What it looks like in practice

You open a terminal inside your project folder and start Claude Code. Before you
type anything, Claude has already been handed your project's note: what the project
is, where it stands, what is half finished, and what was decided and why. You say
"let's carry on with the login work" and it knows what that means.

When the session ends, Claude has added a short dated line to that note about
anything it decided. Next session starts from there.

## What you are about to build

Three small parts, all explained in [04 How it works](04-how-it-works.md):

1. **A vault**: a folder of markdown notes you can browse in the free app Obsidian.
2. **A startup hook**: a tiny script that hands Claude the right note when a
   session starts.
3. **A weekly check**: a script that notices when a note has gone out of date, and
   a Claude skill that helps you fix it.

## Is this for you?

It is a good fit if you:

- use Claude Code on more than one project, or return to projects after days away
- are happy to spend an hour setting up and a few minutes a week keeping it honest
- are on Windows

It is probably not worth it if you only use Claude for one-off questions, or if you
are on a Mac or Linux machine (the scripts are PowerShell and Windows Task
Scheduler; nothing here has been tested elsewhere).

## What you do not need to know

You do not need to know how to code. You do need to be able to open a terminal and
paste commands. Every step in [02 Your first hour](02-first-hour.md) says what you
should see, so you can tell whether it worked. Unfamiliar words are in the
[glossary](glossary.md).

## Next

[01 Prerequisites](01-prerequisites.md)

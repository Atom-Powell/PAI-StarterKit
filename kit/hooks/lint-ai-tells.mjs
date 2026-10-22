#!/usr/bin/env node
// GLOBAL AI-tell backstop for prose written in any project.
// Fires as a PostToolUse (Write|Edit) hook from ~/.claude/settings.json.
//
// Scope: prose files only (.md / .markdown / .mdx / .txt). Dashes are ERRORS
// (hard rule, near-zero false positives). Blocklist words are ADVISORIES -
// flagged for a human look, not automatic failures. ALWAYS non-blocking: it
// reports findings back to the model and user, it never vetoes the edit.

import { readFileSync } from 'node:fs';

const BLOCKLIST = [
  "in today's fast-paced world",
  'ever-evolving',
  'when it comes to',
  'navigating the complexities',
  'navigate the complexities',
  "it's worth noting",
  'it is worth noting',
  "it's important to note",
  'it is important to note',
  'at the end of the day',
  'in conclusion',
  'testament to',
  'game-changer',
  'game changer',
  'cutting-edge',
  'delve',
  'delving',
  'leverage',
  'leveraging',
  'seamless',
  'seamlessly',
  'utilize',
  'utilizing',
  'boasts',
  'tapestry',
  'moreover',
  'furthermore',
  'unlock',
  'elevate',
];

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Precompiled once. Do NOT hoist these into the per-line loop and keep the /g
// flag without resetting lastIndex: a shared global regex carries state between
// calls to .test() and would skip matches.
const TERM_PATTERNS = BLOCKLIST.map((term) => {
  const bounded = /^[a-z]/i.test(term) && /[a-z]$/i.test(term);
  const src = bounded ? `\\b${escapeRe(term)}\\b` : escapeRe(term);
  return { term, re: new RegExp(src, 'gi') };
});

// Replace a span with spaces rather than deleting it, so line numbers and
// columns stay honest.
function blank(match) {
  return ' '.repeat(match.length);
}

// Strip the parts of a markdown line that are NOT prose. Without this, every em
// dash in a code fence, a URL, or a CLI flag is reported as a hard ERROR, and
// blocklist terms match inside identifiers. That matters here specifically:
// "unlock", "elevate", "leverage" and "utilize" are all blocklisted AND are all
// real vocabulary in M365 / security writing (Unlock-ADAccount, privilege
// elevation). A linter that cries wolf in code samples gets ignored, which
// defeats the point of having it.
function maskNonProse(line) {
  return line
    .replace(/`[^`]*`/g, blank)                 // inline code
    .replace(/\]\([^)]*\)/g, blank)             // markdown link targets
    .replace(/\bhttps?:\/\/\S+/g, blank)        // bare URLs
    .replace(/(^|\s)--?[A-Za-z0-9][\w-]*/g, blank); // CLI flags
}

function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function main() {
  let payload;
  try {
    // `|| '{}'` guards the STRING, not the parsed value: JSON.parse('null')
    // returns null and sails straight through. The ?? is what makes the file
    // honor its own "ALWAYS non-blocking" promise.
    payload = JSON.parse(readStdin() || '{}') ?? {};
  } catch {
    process.exit(0);
  }

  const ti = payload.tool_input || {};
  const tr = payload.tool_response || {};
  const filePath = ti.file_path || tr.filePath || '';
  const norm = filePath.replace(/\\/g, '/');

  // Prose files only.
  if (!/\.(md|markdown|mdx|txt)$/i.test(norm)) process.exit(0);

  let text;
  try {
    text = readFileSync(filePath, 'utf8');
  } catch {
    process.exit(0);
  }

  const lines = text.split(/\r?\n/);
  const dashHits = [];
  const wordHits = [];

  const DASH_NAMES = { '–': 'en dash', '—': 'em dash', '―': 'horizontal bar' };
  let inFence = false;

  lines.forEach((rawLine, i) => {
    const ln = i + 1;

    // Fenced code blocks: skip the fence markers and everything between them.
    if (/^\s*(```|~~~)/.test(rawLine)) {
      inFence = !inFence;
      return;
    }
    if (inFence) return;

    const line = maskNonProse(rawLine);

    for (const m of line.matchAll(/[–—―]/g)) {
      dashHits.push({ ln, ch: DASH_NAMES[m[0]] });
    }
    for (const { term, re } of TERM_PATTERNS) {
      // matchAll, not test: `test` on a boolean basis counted a line with three
      // occurrences as one hit, so the dash count and the word count were not
      // measuring the same thing.
      for (const _ of line.matchAll(re)) wordHits.push({ ln, term });
    }
  });

  if (dashHits.length === 0 && wordHits.length === 0) process.exit(0);

  const rel = norm.replace(/^.*\//, '');
  const parts = [];
  if (dashHits.length) {
    parts.push(
      `ERROR - ${dashHits.length} dash tell(s) (no em/en dashes in prose):`,
      ...dashHits.map((h) => `  line ${h.ln}: ${h.ch}`),
    );
  }
  if (wordHits.length) {
    parts.push(
      `ADVISORY - ${wordHits.length} blocklist word(s) (check; some may be legit):`,
      ...wordHits.map((h) => `  line ${h.ln}: "${h.term}"`),
    );
  }
  const detail = `AI-tell lint on ${rel}:\n${parts.join('\n')}`;

  const summaryBits = [];
  if (dashHits.length) summaryBits.push(`${dashHits.length} dash`);
  if (wordHits.length) summaryBits.push(`${wordHits.length} word`);
  const systemMessage = `AI-tell lint: ${rel} - ${summaryBits.join(', ')} flag(s). See details in context.`;

  process.stdout.write(
    JSON.stringify({
      systemMessage,
      suppressOutput: true,
      hookSpecificOutput: {
        hookEventName: 'PostToolUse',
        additionalContext: detail,
      },
    }),
  );
  process.exit(0);
}

// A PostToolUse hook that throws surfaces as a hook error. This file promises in
// its own header that it is ALWAYS non-blocking, so honor that unconditionally.
try {
  main();
} catch {
  process.exit(0);
}

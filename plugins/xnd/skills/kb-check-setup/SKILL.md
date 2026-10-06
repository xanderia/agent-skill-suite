---
name: kb-check-setup
description: Read-only check that the knowledge-base installation actually works — which instruction file (AGENTS.md or CLAUDE.md) holds the anchor, whether Claude Code loads it, whether the base prompt really reached context, import-path hazards, config paths, and base-prompt drift. Changes nothing, fetches nothing.
user-invocable: true
disallowed-tools:
  - Edit
  - Write
  - NotebookEdit
  - Bash
  - WebFetch
  - WebSearch
  - Agent
  - Skill
---


# 🦁 Knowledge Base Setup Check

Answers one question: **is the knowledge-base installation sound, and is it actually reaching this
agent?** It reads a handful of files, compares them with what is in its own context, and reports.

**It changes nothing.** No edits, no shell, no network, no subagents, no other skills: the
frontmatter removes those tools while this skill runs, so this is a guarantee rather than a promise.
The tools may still appear in your tool list, but the harness refuses any call to them, even one the
user has pre-approved (verified 2026-10-05, Claude Code 2.1.289).
It does not offer to fix anything. It names what would fix each finding, and leaves the decision to
the human or their agent. `/xnd:kb-update` is the skill that repairs.

Out of scope by design: bundle content (frontmatter, links, tags), spec drift, external KBs, and
whether a newer plugin version is published. Those belong to `/xnd:kb-update` and
`/xnd:project-review`.


## First — state your version

> 🦁 Knowledge Base Setup Check — plugin v<version>

Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`, or else `.claude-plugin/plugin.json` two
levels up from this skill's own directory. If neither resolves, say `plugin version unknown` and carry
on. Never hardcode the version into this file.


## Check 0 — Look at your context before reading anything

**Do this before you read any file.** Anything you read lands in your context, after which this check
proves nothing.

From the project instructions you received at session start, note:

- which instruction files' content is present: `AGENTS.md`, `CLAUDE.md`, or both;
- whether the knowledge-base section is present, with its `@…` import line visible as text;
- whether the **base prompt's own content** is present. Its `## Bundle Configuration` table is the
  tell.

Write down exactly what you see. Check 3 compares it against the files on disk.

Two caveats, to state in the report whenever they apply:

- Context reflects the files **as they were when this session started**. After a fix, only a fresh
  session shows the effect.
- If the base-prompt file was read earlier in this session, the result is **inconclusive**. Say so and
  suggest re-running the check in a fresh session.


## How agents load the instruction files

The facts needed to judge the setup. They describe what the files do; **which file a project uses is
the project's decision**, and this skill takes no side. Verified against the Claude Code memory
documentation on 2026-10-05 (Claude Code 2.1.289).

| Project root holds | Claude Code loads at session start |
| :--- | :--- |
| `AGENTS.md` only | `AGENTS.md` (2.1.277 or later; some sessions cannot load it natively) |
| `CLAUDE.md` only | `CLAUDE.md` |
| Both, and `CLAUDE.md` contains `@AGENTS.md` | Both. `AGENTS.md` arrives through the import and is read once |
| Both, and `CLAUDE.md` is a symlink to `AGENTS.md` | One file, read once |
| Both, with no import and no symlink | **`CLAUDE.md` only**. `AGENTS.md` is hidden from Claude |

- `.claude/CLAUDE.md` and `CLAUDE.local.md` count as a `CLAUDE.md` for hiding `AGENTS.md`;
  `~/.claude/CLAUDE.md` does not.
- The user's **Project instructions** setting can change the last row: `claude-md-and-agents-md`
  loads both. It lives in user settings, outside this check's view, so mention it as a caveat
  wherever it would change a verdict.
- `@` imports are expanded in both files. They resolve relative to the importing file and nest at
  most four hops deep.
- Other coding agents generally read `AGENTS.md`, and many do not expand `@` imports. They find the
  base prompt only through a plain markdown link that tells them to read it.
- Block-level HTML comments are stripped before Claude sees a file, so the `<!-- okf:installed -->`
  marker is visible only on disk.
- Edit and Write refuse to write through a symlink, so edits go to the symlink's target.


## The checks

Run all of them, even after a failure. One broken link in the chain usually explains the others, and
the report should show the whole chain.

### 1. Instruction files

Read root `AGENTS.md` and root `CLAUDE.md` from disk, plus `.claude/CLAUDE.md` and `CLAUDE.local.md`
when present. A missing file is a fact, not an error. In each file, find the `<!-- okf:installed -->`
marker.

- **Exactly one file holds the marker.** That file is the *anchor file*. ✅
- **Neither file holds it.** The knowledge base is not installed here (`/xnd:kb-update` installs it).
  Report what exists and stop.
- **Both files hold it.** ❌ Two anchors, and an import could run twice.
- If `CLAUDE.md` and `AGENTS.md` have **identical content**, the file is either a symlink, which is
  fine, or a copy, which will drift. Without a shell you cannot tell which, so say so.

### 2. Claude Code loads the anchor file

Apply the table above to the files that exist. Report which file Claude Code loads, and whether the
anchor file is among them.

- Not loaded: ❌. Every rule in the base prompt is silently missing for Claude.
- Loaded only because of a `@AGENTS.md` import or a symlink: ✅, and name that dependency. Deleting
  the import or the symlink would break it.
- Also say whether agents that read only `AGENTS.md` will see the anchor. That is information, not a
  verdict.

### 3. The base prompt reached context — the decisive check

Compare Check 0 against the disk:

| Anchor file loaded (Check 2) | Base prompt in context (Check 0) | Meaning |
| :--- | :--- | :--- |
| yes | yes | ✅ The whole chain works |
| yes | **no** | ❌ **The import is broken.** Check 5 usually says why |
| no | no | ❌ Explained by Check 2 |
| no | yes | ⚠️ Something outside the table loads it: a user setting, a `.claude/rules/` file, or another import. Name it if you can |

A broken import fails silently: no error, and the anchor's sentence still reads like the rules are
there. This check exists because exactly that went unnoticed for five weeks.

### 4. Configuration

Find `Configuration.yaml`. The anchor names the bundle directory (`{Metadata_Dir}`). Try
`{Metadata_Dir}/_Configuration_/Configuration.yaml`, then `.yml`. If the anchor names no directory,
try `Notes/`. A legacy install keeps its config as `okf_*` keys in `{Metadata_Dir}/index.md`
frontmatter instead. That is ⚠️; `/xnd:kb-update` migrates it. `okf_version` alone in that
frontmatter is correct and not legacy: OKF §12 puts it there.

Then confirm that every `layout` path exists:

- `layout.root` and `layout.metadata_dir` each have an `index.md`. A root of `/` means the project
  root's `index.md`.
- `layout.base_prompt` and `layout.review_prompt` exist.
- When `layout.skill_source` is set, `{skill_source}/.claude-plugin/plugin.json` exists.
- When `layout.task_list` is set, the file exists.

A missing required key is ❌ and names the key.

### 5. Anchor shape and import path

In the anchor file's section, expect a heading, the marker comment, a sentence with a markdown link to
the base prompt, and an `@` import line. Then check the import path. Each item below is a silent
failure, and Check 3 shows whether it bit:

- **A `_Name_` or `*Name*` segment** (for example `_Workflows_`) is ❌. Markdown reads it as emphasis,
  the path splits, and nothing is imported. Escaping (`\_`) does not help. Underscores inside a word
  (`snake_case`) are fine.
- **An unescaped space** is ❌, because the path ends at the space. Each space must be written `\ `.
- **A quoted path, or an import inside a code span or fenced block**, is ❌: it is not imported.
- **The unescaped import path must equal `layout.base_prompt`**, and the link, percent-decoded, must
  resolve to the same file. A mismatch is ⚠️: config, link and import have drifted apart.
- **No link** is ⚠️. Claude still loads the file, but agents that do not expand `@` imports cannot
  find it.

### 6. Base prompt matches the config

Now read the base prompt. Its `## Bundle Configuration` table must quote each of these config values
**verbatim, in a code span**:

- `spec.sha`, `layout.root`, `layout.metadata_dir`
- `naming.files`, `naming.folders`, `naming.dates_in_filenames`
- `zones.ignore` and `verifier`

Any value that is missing or different is ⚠️. The base prompt is teaching stale rules, and
`/xnd:kb-update` regenerates it. The project's own verifier may check this too, but this skill does
not run it.

### 7. Import depth

Count the hops from the file Claude Code loads to the base prompt. `CLAUDE.md` → `AGENTS.md` → base
prompt is two hops; more than four is ❌. The base prompt must not itself `@`-import anything outside
a code span. Chained base prompts are ⚠️.


## Report

Open with the version line, then a single table:

| # | Check | Result | Evidence |
| :--- | :--- | :--- | :--- |
| 1 | Instruction files | ✅ / ⚠️ / ❌ | The files found, and which holds the marker |
| … | | | Quote the exact line, path or value |

Then:

1. **Verdict.** One sentence on whether the knowledge base is reaching Claude in this session, plus
   any caveat from Check 0.
2. **What would fix it.** For each ⚠️ and ❌, give the remedy and its consequence, not a
   recommendation:
   - Problems with the anchor shape, the import path, config drift or a legacy config: run
     `/xnd:kb-update`. Its Phase 0 repairs them.
   - An anchor file Claude does not load is a choice for the human or their agent. The options are:
     add `@AGENTS.md` to `CLAUDE.md`; move the anchor into the file that is loaded; replace
     `CLAUDE.md` with a symlink to `AGENTS.md` (this does not survive a Windows clone); or change the
     *Project instructions* setting (which applies to that user only). Give the trade-off of each in
     one line.

**Cite the migration entry.** The plugin ships `Update Migration.md`
(`${CLAUDE_PLUGIN_ROOT}/Update Migration.md`, or `../../Update Migration.md` from this skill's
directory). It lists what each version needs from an existing installation. When a finding matches
one of its entries, add the entry's ID (for example `0.9.0-A`) to the finding, so the human can look up
the background and the fix. Do not walk its other entries: anything outside this skill's checks is
`/xnd:kb-update`'s job.

State plainly anything you could not check, such as a file you were not permitted to read. A clean
report that skipped a check is worse than an honest partial one.

$ARGUMENTS

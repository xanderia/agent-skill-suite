---
name: plugin-uninstall
description: Remove the OKF knowledge-base scaffolding this plugin installed — frontmatter, generated folders, config and the AGENTS.md or CLAUDE.md section — with a dry-run diff and per-item confirmation
user-invocable: true
---


# 🦁 Plugin Uninstall

Removes what `/xnd:kb-update` installed, and leaves the project's actual knowledge intact unless
explicitly told otherwise.

This is **not** the same as removing the plugin. Removing the plugin stops the skills from loading;
this skill removes the *scaffolding in the project*. Most people want one or the other, rarely both
at once — say so plainly at the start.

> ⚠️ **Stripping frontmatter is irreversible without git.** Nothing here runs without a dry-run and
> an explicit confirmation.


## First — state your version

Open with one line naming the skill and the plugin version you are running:

> 🦁 Plugin Uninstall — plugin v<version>

Resolve `plugin.json` by trying, in order, until one exists:

1. `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
2. `.claude-plugin/plugin.json` two levels up from this skill's own directory — this file lives at
   `plugins/<name>/skills/<skill>/SKILL.md`, so the manifest is `../../.claude-plugin/plugin.json`
3. `{layout.skill_source}/.claude-plugin/plugin.json`, when the project vendors the suite

If none resolves, say `plugin version unknown` and carry on. **Never hardcode the version into this
file** — `plugin.json` is the single source of truth, and a copy here would drift.

**Do not check for a newer version.** Someone uninstalling has no use for an upgrade prompt, and a
network call here is pure noise. State the local version so the human can see what wrote the changes,
and nothing more.


## Step 1 — Take stock

1. Read the config from `{Metadata_Dir}/_Configuration_/Configuration.yaml` — resolved
   case-insensitively, accepting `.yaml` or `.yml`, since the project's own naming convention governed
   how `/xnd:kb-update` created it. A bundle predating that file keeps its config as `okf_*` keys in
   `{Metadata_Dir}/index.md` frontmatter; fall back to reading it there. `okf_version` legitimately
   lives in `index.md` either way.

   Then find the `<!-- okf:installed -->` marker. **Read both root `AGENTS.md` and root `CLAUDE.md`
   from disk with the Read tool**, whichever exist — the anchor may be in either, and `AGENTS.md` is
   where `/xnd:kb-update` puts a new one. The file holding the marker is *the instruction file* for
   the rest of this run; a `CLAUDE.md` symlinked to `AGENTS.md` is one file, edited as `AGENTS.md`.
   Block-level HTML comments are stripped before a `CLAUDE.md` reaches the model, so checking context
   alone reports "not installed" for a perfectly good install. The base prompt's `@` import line is
   the visible counterpart. If neither marker nor config exists, say the plugin was never installed
   here and stop.
2. Check whether the working tree is clean. If it is dirty, say so and recommend committing first —
   git is the only undo.
3. Inventory what exists:
   - concept files carrying frontmatter, grouped by folder, with counts
   - folders this plugin creates (`_Archive_`, `_Plans_`, `_Plans_/_ReviewReports_`,
     `_Plans_/_Archive_`, `_Workflows_`, and the base prompt's own folder — `Knowledge Base/` cased per
     `naming.folders`, or `_Workflows_/knowledge-base/` on a pre-0.9.0 install) and whether each holds
     content the human wrote
   - the instruction file's anchor section **and** the base prompt it imports (`layout.base_prompt`) —
     these are one unit: removing the anchor while leaving the file orphans it, and removing the file
     while leaving the anchor leaves a broken import in the human's instruction file
   - the config itself — `_Configuration_/Configuration.yaml`, or the legacy `okf_*` frontmatter in
     `{Metadata_Dir}/index.md` on a pre-0.5.0 bundle


## Step 2 — Ask what to remove

Use the AskUser tool. **Never assume "uninstall" means "remove everything".**

1. **Frontmatter** — which folders to strip it from. Multi-select, listing each folder with its file
   count. Default: none selected. Removing frontmatter turns concept documents back into plain
   markdown; the prose survives untouched.
2. **Folders** — which of the created folders to delete, **one entry per folder**, each stating what
   it currently contains. A folder holding the human's own plans or reports must be marked
   `(contains your work)` and must never be pre-selected.
3. **The instruction-file anchor and its base prompt** — remove both, or keep the base prompt as
   ordinary documentation and drop only the import? Offer inlining the base prompt back into the
   instruction file as a third option: it is what a human who wants the guidance but not the plugin
   usually means.

   An `@AGENTS.md` line in `CLAUDE.md` is **not** offered for removal. `/xnd:kb-update` may have added
   it, but it is the standard way to share one file between Claude and other agents, harmless without
   the plugin, and it may well predate it. Leave it and say so in the report.
4. **The config** — `_Configuration_/Configuration.yaml` (or the legacy `okf_*` frontmatter in
   `{Metadata_Dir}/index.md`) — remove, or keep so a future reinstall remembers the settings? Leave
   `okf_version` in `index.md` alone unless the whole bundle is being dismantled; it is the one
   spec-defined key, and OKF §12 puts it there.


## Step 3 — Dry run, then confirm

Show exactly what *would* happen before anything happens:

- a per-file diff of frontmatter removal (or a representative sample plus a total, when it runs to
  many files)
- the full list of folders and files that would be deleted
- the instruction-file diff, and the fate of the base prompt file

Then ask for a final confirmation. **Anything other than a clear yes stops the run.** If they decline,
say nothing was touched and offer to narrow the selection.


## Step 4 — Execute

Apply exactly what was confirmed — nothing adjacent, nothing "while we're here".

- Strip only the frontmatter block: everything between the opening `---` and its closing `---`, plus
  the blank line that follows. Never touch the body.
- Be fence-aware — `---` and `type:` appear inside documentation code blocks as examples.
- Never delete a folder that was not explicitly confirmed.


## Step 5 — Report

Warm, joyous, plain. Then a table, because the point is that they can see exactly what happened:

| Item | Action | Detail |
| :--- | :--- | :--- |
| `Notes/Client/` | Frontmatter removed | 23 files |
| `Notes/_Plans_/` | **Kept** | Your plans are still here |
| `Notes/_Plans_/_ReviewReports_/` | **Kept** | 2 reports preserved |
| Anchor in `AGENTS.md` (or `CLAUDE.md`) | Removed | — |
| `@AGENTS.md` in `CLAUDE.md` | **Kept** | Standard shim; harmless without the plugin |
| Base prompt (`layout.base_prompt`) | Removed / inlined / kept | — |
| `Configuration.yaml` | **Kept** | A reinstall will remember your settings |

Close with:

> The scaffolding is gone, and your writing is exactly where you left it. If you'd also like to
> remove the skills themselves, you can now do that with `/plugin` — this skill only cleans up the
> project, not the plugin.

If anything was skipped or failed, say so in the same table. A cheerful report that hides a failed
deletion is worse than no report.

$ARGUMENTS

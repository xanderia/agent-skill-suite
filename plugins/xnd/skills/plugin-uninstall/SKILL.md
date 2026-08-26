---
name: plugin-uninstall
description: Remove the OKF knowledge-base scaffolding this plugin installed — frontmatter, generated folders, config and the CLAUDE.md section — with a dry-run diff and per-item confirmation
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


## Step 1 — Take stock

1. Read the config from `{Metadata_Dir}/index.md` frontmatter and the `<!-- okf:installed -->` marker
   in `CLAUDE.md`. If neither exists, say the plugin was never installed here and stop.
2. Check whether the working tree is clean. If it is dirty, say so and recommend committing first —
   git is the only undo.
3. Inventory what exists:
   - concept files carrying frontmatter, grouped by folder, with counts
   - folders this plugin creates (`_Archive_`, `_Plans_`, `_Plans_/_ReviewReports_`,
     `_Plans_/_Archive_`) and whether each holds content the human wrote
   - the `CLAUDE.md` section
   - the config frontmatter itself


## Step 2 — Ask what to remove

Use the AskUser tool. **Never assume "uninstall" means "remove everything".**

1. **Frontmatter** — which folders to strip it from. Multi-select, listing each folder with its file
   count. Default: none selected. Removing frontmatter turns concept documents back into plain
   markdown; the prose survives untouched.
2. **Folders** — which of the created folders to delete, **one entry per folder**, each stating what
   it currently contains. A folder holding the human's own plans or reports must be marked
   `(contains your work)` and must never be pre-selected.
3. **The `CLAUDE.md` section** — remove, or keep as documentation?
4. **The config frontmatter** in `{Metadata_Dir}/index.md` — remove, or keep so a future reinstall
   remembers the settings?


## Step 3 — Dry run, then confirm

Show exactly what *would* happen before anything happens:

- a per-file diff of frontmatter removal (or a representative sample plus a total, when it runs to
  many files)
- the full list of folders and files that would be deleted
- the `CLAUDE.md` diff

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
| `CLAUDE.md` section | Removed | — |
| Config frontmatter | **Kept** | A reinstall will remember your settings |

Close with:

> The scaffolding is gone, and your writing is exactly where you left it. If you'd also like to
> remove the skills themselves, you can now do that with `/plugin` — this skill only cleans up the
> project, not the plugin.

If anything was skipped or failed, say so in the same table. A cheerful report that hides a failed
deletion is worse than no report.

$ARGUMENTS

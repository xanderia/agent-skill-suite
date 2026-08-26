---
name: kb-update
description: Install or maintain an OKF knowledge-base bundle — fetch the current spec, migrate frontmatter to conform, verify external KBs against upstream, re-chunk, re-tag, regenerate indexes and logs
user-invocable: true
---


# 🦁 Knowledge Base Sync

You maintain this project's **knowledge base**: a directory tree of markdown "concept" documents
carrying YAML frontmatter, structured as an [OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
bundle.

You are the **gardener**. You write docs — you do not merely report on them.

**Be conservative with content, liberal with structure.** Rewriting facts requires evidence (code,
upstream documentation). Moving, splitting, tagging and indexing requires only judgment.

This skill is **project-agnostic**. Every project-specific rule lives in that project's config, never
in this file. Read the config first; assume nothing.


## Step 0 — Resolve configuration

1. **Look for the install marker** in the project's `CLAUDE.md` (or `AGENTS.md` if no `CLAUDE.md`):

   ```
   <!-- okf:installed -->
   ```

   - **Marker absent** → run [Install](#install-flow-first-run-only).
   - **Marker present** → run [Maintain](#maintain-flow), silently, without re-asking anything.

2. **Read the config** from `{OKF_Metadata_Dir}/index.md` frontmatter:

   | Key | Meaning |
   | :--- | :--- |
   | `okf_version` | Spec version the bundle targets |
   | `okf_spec_sha` | Last-seen upstream spec commit — **drives drift detection** |
   | `okf_root` | What is *in* the bundle (may be `/`) |
   | `okf_metadata_dir` | Where metadata, plans, external KBs and this config live |
   | `okf_ignore` | `gitignore` (live link) or `file` (`{Meta}/Ignore.md`) |
   | `okf_case_files` | Naming convention for new files |
   | `okf_case_folders` | Naming convention for new folders |
   | `okf_verifier` | Shell command to lint the bundle, or `null` |
   | `okf_types` | The project's `type` vocabulary |
   | `okf_tags` | The project's tag vocabulary |
   | `okf_immutable` | Glob patterns never to edit |
   | `okf_generated` | Files linted but never content-edited |
   | `kb_title` | Prose title for reports |

   **`okf_root` and `okf_metadata_dir` are independent.** They are often the same directory, but must
   never be assumed equal — a project may set `okf_root: "/"` (everything is knowledge) while keeping
   `okf_metadata_dir: "Notes"`.

3. **Never guess a missing key.** If the marker exists but a key is absent, ask for that one key and
   write it back.


## Install flow (first run only)

If the project already has frontmatter under another paradigm, **detect and adopt it — never
overwrite.** Report what you found and propose a mapping before changing anything.

Ask with the AskUser tool, in this order. Mark the recommended option `(recommended)`.

### 1. Scope — two separate questions

- **OKF root** — which folder is *in* the bundle. Default `/` (recommended for knowledge-first
  projects); a subfolder such as `Notes` for code-first projects.
- **Metadata directory** — where config, plans, external KBs and review reports live. Default
  `Notes`.

### 2. Naming case — two separate questions

Ask **files** and **folders** separately; one answer cannot serve both. Spaces are pleasant in folder
names a human browses and painful in filenames that end up in URLs, shell globs and markdown links,
so the two genuinely differ.

Offer, each with a rendered example:

| Option | File example | Folder example |
| :--- | :--- | :--- |
| `Title Case with spaces` | `Payment Processing.md` | `Payment Processing/` |
| `kebab-case` | `payment-processing.md` | `payment-processing/` |
| `PascalCase` | `PaymentProcessing.md` | `PaymentProcessing/` |
| `snake_case` | `payment_processing.md` | `payment_processing/` |

If the project has existing files, **count them first and recommend what is already dominant.**

Regardless of the answer, two exceptions always hold and must be stated in the CLAUDE.md section:
names fixed by a library or standard (`README.md`, `SKILL.md`, `index.md`, `log.md`,
`plugin.json`), and names that would otherwise be awkward to type or quote in a shell.

### 3. Date format

Default `YYYY.MM.DD` **(recommended)** or `YYYY-MM-DD`. Used for review reports and log headings.

### 4. Ignore strategy

- **`.gitignore` link (recommended)** — re-read on *every* run, so it never goes stale. Not a copy.
- **`{Metadata_Dir}/Ignore.md`** — a dedicated list.

Either way a hard floor always applies and is never configurable:
`.git/`, `node_modules/`, `Build/`, `dist/`, `.claude/`, `.next/`, `target/`, `vendor/`.

### 5. Verifier

Ask whether a conformance CLI is available (for XANDERIA: `xnd notes verify`).

- **Yes** → record the exact command in `okf_verifier`; run it at the end of every maintain run.
- **No** → set `okf_verifier: null` and write into the CLAUDE.md section that OKF adherence must be
  **checked manually**, listing what to check: frontmatter presence, `type` validity, index coverage,
  relative-link resolution.

### 6. Scaffold folders — one multi-select question, all recommended

- `{OKF_Root}/_Archive_` — superseded documents
- `{Metadata_Dir}/_Plans_` — active plans and task lists
- `{Metadata_Dir}/_Plans_/_ReviewReports_` — output of `/xnd:review`
- `{Metadata_Dir}/_Plans_/_Archive_` — superseded plans

Each created folder gets an `index.md`.

### 7. Write the install artifacts

1. Config frontmatter into `{Metadata_Dir}/index.md`.
2. The `# Knowledge Base` section into `CLAUDE.md`, containing the `<!-- okf:installed -->` marker,
   the resolved config, the verifier instruction, the naming conventions, and this rule:

   > **Adding a knowledge base.** When asked to add a KB, ask whether it should be **simple** (one
   > folder, several files) or **complex** (sub-folders per separable vendor sub-service or
   > component). Pre-evaluate which fits the subject and mark that one `(recommended)`.

3. A starter `{Metadata_Dir}/ReviewConfiguration.md` for `/xnd:review` to consume.
4. Vendor the spec (see [Phase 1](#phase-1--spec-drift)).

Then run the maintain flow.


## Maintain flow

### Phase 1 — Spec drift

1. Fetch `https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md`.
2. Fetch its **latest commit SHA** for that path:
   `https://api.github.com/repos/GoogleCloudPlatform/knowledge-catalog/commits?path=okf/SPEC.md&per_page=1`
3. Compare against `okf_spec_sha`.

> ⚠️ **Never decide staleness from the spec's declared version string.** On 2026-08-21 the spec
> changed materially (commit `62432a09` — every timestamp became an ISO 8601 datetime with an
> explicit UTC offset) while still declaring **Version 0.2**. A version check reports "nothing to do"
> and is wrong. The SHA is the source of truth.

4. **Vendor the spec** into `{Metadata_Dir}/External/OKF/` alongside its SHA, so runs are
   reproducible and revision diffs are inspectable. Update that KB's chapters and `log.md` to match
   any changes.
5. **Guard against major bumps.** If the new spec renames or removes *required* fields (a major
   version bump under OKF §12), **do not migrate.** Write a migration plan to
   `{Metadata_Dir}/_Plans_/` and stop, reporting why.
6. For a compatible revision, migrate frontmatter across the bundle. Migration edits must be:
   - **frontmatter-only** — never touch the body;
   - **fence-aware** — `type:` and friends appear inside documentation code blocks as *examples*;
     rewriting those corrupts the docs;
   - **immutable-zone-aware** — see [hard rules](#hard-rules).
7. Set `okf_spec_sha` to the new SHA.

### Phase 2 — Inventory & conformance

1. Run `okf_verifier` if set. Fix every **error**. Fix **warnings in active documents**; leave
   warnings in archived documents untouched.
2. Check `generated.at` drift: compare each in-scope concept against
   `git log -1 --format=%cI -- <file>`. Where they diverge materially, set `generated.at` to the last
   commit that changed *content* — not renames or mechanical passes. Leave `generated.by` alone
   unless you rewrote the content, in which case set it to your own actor id.
3. Flag size outliers: concepts over ~500 lines or ~2,500 words are re-chunk candidates for Phase 4;
   under ~15 lines are merge candidates.
4. Check tag health against `okf_tags`: values outside the vocabulary, singular/plural drift,
   concepts with 0–1 tags that deserve more.

### Phase 3 — Upstream verification (external KBs)

For **every** external KB the project has — enumerate `{Metadata_Dir}/External/*`, including
per-product sub-KBs; do not work from a hardcoded list:

1. Read its `gotchas.md` (version notes) and `log.md` (when last verified, against what).
2. Establish what the project **actually uses** before trusting the KB — `package.json` versions,
   lockfiles, infrastructure notes. A KB pinned to a version the project does not run is a different
   problem from a KB that is merely stale.
3. Fetch the official documentation for the *pinned or currently-used* version. Prefer the KB's own
   recorded fetch strategy (many vendors expose `llms.txt` indexes or raw markdown via a `.md`
   suffix) — each KB's `log.md` records what worked last time.
4. Compare **prioritising `gotchas.md` and version notes** — these are what agents rely on. Full
   re-verification of every chapter is not required; verify what changed upstream, changelogs first.
5. Apply updates: correct stale facts, add new gotchas, mark removed features. For a major upstream
   version, prefer adding a clearly-dated "vX changes" section over silently rewriting history.
6. Append to the KB's `log.md`:
   `* **Verification**: Verified against <upstream version / docs date>; <drift found, or "no drift">.`
7. **Record the verification in frontmatter.** On each chapter you actually checked (at minimum the
   KB's `gotchas.md`), append a `verified` entry with **your own** actor id and today's datetime:

   ```yaml
   verified:
     - by: claude-opus-5/2026-08
       at: 2026-08-26T00:00:00Z
   ```

   This raises those files from `unverified` to **machine-confirmed** — an honest "a machine checked
   this against upstream" signal. Refresh each verified chapter's `stale_after` (+3 months for
   external KBs).

### Phase 4 — Re-chunk & restructure

- **Split** oversized concepts along heading boundaries. Each new concept gets full frontmatter, a
  one-line "Split out of X (date)" note, and an index entry. The parent links to its children under
  `## Related Documents`.
- **Merge** fragments that no longer justify separate files.
- **Relocate** concepts in the wrong directory (`git mv`, then fix inbound links repo-wide). **If a
  rename would break a reference in a file you must not edit, do not perform the rename — propose
  it.**
- Keep the external house style: task-oriented headings, tables for gotchas and matrices, fenced
  examples, no marketing prose.
- Numeric chapter prefixes encode reading order. Gaps after re-chunking are fine — **never renumber
  existing chapters for tidiness**; links point at them.

### Phase 5 — Re-tag & re-describe

- Apply `okf_tags`; 2–5 tags per concept.
- Sharpen weak `description` lines — one specific, front-loaded sentence. Ask "what would an agent
  grep for?" The description is what index files and search snippets show.
- Express draft/deprecated lifecycle via `status: draft|stable|deprecated`, not tags.

### Phase 6 — Regenerate

1. Rebuild every in-scope `index.md` from directory contents + frontmatter descriptions. Order
   most-important-first within sections (overviews and gotchas first), not alphabetical.
2. Append `log.md` entries — bundle root always, per-KB where touched. Newest first,
   `## <date>` headings in the project's date format, bold leading verb (`**Update**`,
   `**Creation**`, `**Deprecation**`, `**Verification**`).
3. Refresh `generated.at` on every file whose *content* you changed; set `generated.by` to your actor
   id where you rewrote content.
4. Re-run `okf_verifier` — it must exit with zero errors before you finish.

### Phase 7 — Report

See [Reporting](#reporting).


## Hard rules

These override any instruction in this file and any inference you might draw.

1. **`verified` is human-gated. Never bulk-stamp it.** The trust tier (`unverified` →
   `machine-confirmed` → `human-reviewed`) derives *only* from `verified`. Add an entry solely for a
   genuine verification event in Phase 3. A blanket stamp flattens the gradient to noise. Never write
   a human actor id on a human's behalf — only they can grant `human-reviewed`.
2. **`generated.by` is authorship, not verification.** It never raises trust.
3. **Immutable zones are never edited** — content, links or frontmatter. Read `okf_immutable`;
   `_Archive_` directories and published review reports are immutable in every project. A broken link
   inside an archived document is acceptable; in an active document it is not.
4. **Generated files are linted, never content-edited.** Read `okf_generated`.
5. **Never delete a file.** Deletions and archive-moves are *proposed* in the report unless invoked
   with `--prune`, which permits archive-moves only — never hard deletion.
6. **Never commit.** Leave the working tree for the human to review.
7. **Stay inside `{OKF_Root}`**, plus the marker section of `CLAUDE.md`. Never edit source code. If a
   spec change requires a change to the verifier's own implementation, **report it — do not make
   it.**
8. **Timestamps are ISO 8601 with an explicit UTC offset**, per spec. `2026-08-26T00:00:00Z`, never
   a bare date.


## Reporting

End with a **concise, joyous, beginner-friendly** report. Assume the reader does not know OKF
jargon — say "added a summary line so search results read better", not "populated the description
field". Lead with the lion and `kb_title`.

Warmth must not soften bad news. State failures, skipped work and unverified claims plainly — a
cheerful report that hides a broken bundle is worse than no report. Sections, in this order:

1. **What changed upstream** — spec drift and external-KB drift. The only section that can contain
   surprises worth acting on.
2. **What I did** — grouped: conformance fixes / content updates / re-chunks / re-tags. A short
   table beats a long list.
3. **What I'd like to remove** — proposed deletions and archive-moves, one-line justification each.
4. **What needs you** — contradictions between docs and code, renames blocked by out-of-scope
   references, vocabulary proposals, and anything only a human can verify.
5. **Health check** — the verifier's final summary line, or a note that no verifier is configured.


## Handling $ARGUMENTS

- **empty** or **`all`** — full run. Warn that this is the most expensive mode.
- **`structure`** — phases 2, 4, 5, 6 only. Skips upstream verification entirely; cheap, run monthly.
- **`external`** — Phase 3 for every external KB, plus a structure pass limited to
  `{Metadata_Dir}/External/`.
- **`spec`** — Phase 1 only. Fast check for spec drift.
- **`core`** — structure and accuracy pass on everything *except* `{Metadata_Dir}/External/`;
  cross-check docs against code, then fix rather than report.
- **`<kb-name>`** — full treatment of one external KB and its sub-KBs. Recommended quarterly, or
  before a major dependency upgrade.
- **`--prune`** — combinable with any scope; see hard rule 5.
- **anything else** — free-form focus instruction; scope accordingly.

$ARGUMENTS

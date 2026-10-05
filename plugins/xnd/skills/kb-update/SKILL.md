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


## Spec baseline

This skill's instructions were written against OKF spec commit **`62432a09`** (2026-08-21).
[Phase 1b](#phase-1b--self-update) updates this line when the spec moves.


## First — state your version

Open with one line naming the skill and the plugin version you are running:

> 🦁 Knowledge Base Sync — plugin v<version>

Resolve `plugin.json` by trying, in order, until one exists:

1. `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
2. `.claude-plugin/plugin.json` two levels up from this skill's own directory — this file lives at
   `plugins/<name>/skills/<skill>/SKILL.md`, so the manifest is `../../.claude-plugin/plugin.json`
3. `{layout.skill_source}/.claude-plugin/plugin.json`, when the project vendors the suite

If none resolves, say `plugin version unknown` and carry on. **This is never a reason to stop**, and
it is not worth a retry loop.

**Never hardcode the version into this file.** `plugin.json` is the single source of truth; a copy
here would be a second one, and it would drift — the same reasoning that keeps `okf_version` out of
`Configuration.yaml`.


## Instruction file

The anchor lives in one of the project's agent instruction files, `AGENTS.md` or `CLAUDE.md`. This
file calls the one holding it `{Instructions_File}`.

- **Read both from disk** with the Read tool. The `<!-- okf:installed -->` marker can be in either, and
  context cannot be trusted (see the warning below).
- **An existing anchor stays where it is.** Never move a working anchor. If both files carry a marker,
  report it and ask which to keep.
- **For a new install, choose.** The facts that decide it — which file Claude Code loads, when a
  `CLAUDE.md` hides an `AGENTS.md`, how imports and symlinks behave, what other agents read — are in
  [How agents load the instruction files](../kb-check-setup/SKILL.md#how-agents-load-the-instruction-files).
  Put the anchor in the file the project already relies on. The one hard requirement is that Claude
  Code loads it. If meeting that requirement needs a change to another file the human owns, such as
  an `@AGENTS.md` line in `CLAUDE.md`, say what and why, and ask first.

> ⚠️ **Read the files; do not trust context.** Block-level HTML comments are stripped from a
> `CLAUDE.md` — and from whatever it imports — before it reaches the model, so the marker is
> invisible in your context even when it is present on disk. Deciding from context alone yields a
> false negative and a destructive re-install over a working setup. The `@` import line of the base
> prompt *is* visible in context — which is why it doubles as the marker.


## Step 0 — Resolve configuration

1. **Resolve `{Instructions_File}`** per [Instruction file](#instruction-file).

   - **Marker absent** → run [Install](#install-flow-first-run-only).
   - **Marker present** → run [Maintain](#maintain-flow), silently, without re-asking anything.

2. **Read the config** from `{OKF_Metadata_Dir}/_Configuration_/Configuration.yaml`:

   | Key | Meaning |
   | :--- | :--- |
   | `spec.sha` | Last-seen upstream spec commit — **drives drift detection** |
   | `layout.root` | What is *in* the bundle (may be `/`) |
   | `layout.metadata_dir` | Where config, plans, external KBs live |
   | `layout.base_prompt` | The always-loaded prompt `{Instructions_File}` imports — the real, unescaped path |
   | `layout.review_prompt` | The review contract `/xnd:project-review` reads |
   | `layout.skill_source` | Path to this suite's own source, when the project vendors it — enables [Phase 1b](#phase-1b--self-update). Absent → report needed changes, never self-edit |
   | `naming.files` / `naming.folders` | Case convention for new files and folders |
   | `naming.dates_in_filenames` | Date format **for filenames only** — never for `log.md` headings, which OKF §7 fixes as ISO `YYYY-MM-DD` |
   | `naming.reserved` / `naming.reserved_folders` | Names that keep their given form regardless of case rules |
   | `vocabulary.types` / `vocabulary.tags` | The project's `type` and tag vocabularies |
   | `zones.ignore` | `gitignore` (live link) or `file` (`{Meta}/Ignore.md`) |
   | `zones.immutable` | Glob patterns never to edit |
   | `zones.generated` | Files linted but never content-edited |
   | `verifier` | Shell command to lint the bundle, or `null` |
   | `title` | Prose title for reports |

   **`okf_version` is not in this file.** OKF §12 places it in the bundle-root `index.md`
   frontmatter, which is where a spec-only consumer looks. It is the one spec-defined key, and no key
   lives in two places — read it from there when you need it.

   **`layout.root` and `layout.metadata_dir` are independent.** They are often the same directory, but
   must never be assumed equal — a project may set `root: "/"` (everything is knowledge) while keeping
   `metadata_dir: "Notes"`.

   **The human is expected to edit this file by hand.** Everything derived from it — above all the
   base prompt — is regenerated in [Phase 0](#phase-0--verify-the-installation), never patched around.

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

Regardless of the answer, two exceptions always hold and must be stated in the base prompt:
names fixed by a library or standard (`README.md`, `SKILL.md`, `index.md`, `log.md`,
`plugin.json`), and names that would otherwise be awkward to type or quote in a shell.

### 3. Date format

Default `YYYY.MM.DD` **(recommended)** or `YYYY-MM-DD`. Used for **filenames** — review reports and
anything else dated. It does **not** govern `log.md` date headings, which OKF §7 fixes as ISO
`YYYY-MM-DD` regardless of this answer; say so when you ask, because letting the filename convention
leak into log headings is a conformance error that is easy to make and hard to notice.

### 4. Ignore strategy

- **`.gitignore` link (recommended)** — re-read on *every* run, so it never goes stale. Not a copy.
- **`{Metadata_Dir}/Ignore.md`** — a dedicated list.

Either way a hard floor always applies and is never configurable:
`.git/`, `node_modules/`, `Build/`, `dist/`, `.claude/`, `.next/`, `target/`, `vendor/`.

### 5. Verifier

Ask whether a conformance CLI is available (for XANDERIA: `xnd notes verify`).

- **Yes** → record the exact command in `verifier`; run it at the end of every maintain run.
- **No** → set `verifier: null` and write into the base prompt that OKF adherence must be
  **checked manually**, listing what to check: frontmatter presence, `type` validity, index coverage,
  relative-link resolution.

### 6. Scaffold folders — one multi-select question, all recommended

- `{OKF_Root}/_Archive_` — superseded documents
- `{Metadata_Dir}/_Plans_` — active plans and task lists
- `{Metadata_Dir}/_Plans_/_ReviewReports_` — output of `/xnd:project-review`
- `{Metadata_Dir}/_Plans_/_Archive_` — superseded plans
- `{Metadata_Dir}/Knowledge Base` — named per `naming.folders` (`knowledge-base`, `KnowledgeBase`, …);
  holds the base prompt `{Instructions_File}` imports. **Never inside a `_Name_` marker directory** —
  an `@` import cannot pass through one; see [Anchor constraints](#anchor-constraints)
- `{Metadata_Dir}/_Workflows_` — holds `Review Prompt.md`, which is read on demand, never imported
- `{Metadata_Dir}/_Configuration_` — holds `Configuration.yaml`; **not optional**, the rest of the
  skill reads it

Each created folder gets an `index.md`.

### 7. Write the install artifacts

1. **`{Metadata_Dir}/_Configuration_/Configuration.yaml`** — every answer above, grouped under
   `spec`, `layout`, `naming`, `vocabulary`, `zones`, plus `verifier` and `title`. Write it with
   comments: it is meant to be read and edited by a human. Put `okf_version` in the bundle-root
   `index.md` frontmatter instead, per OKF §12 — and nowhere else.
2. **The base prompt** at `layout.base_prompt` — `{Metadata_Dir}/Knowledge Base/Base Prompt.md`, both
   names cased per `naming.folders` and `naming.files`. A normal concept document (full frontmatter,
   listed in its directory's `index.md`) carrying the resolved config, the verifier instruction, the
   naming conventions, the immutable-zone and archiving rules, and this rule:

   > **Adding a knowledge base.** When asked to add a KB, ask **two** questions before writing
   > anything, each with one option pre-marked `(recommended)`:
   >
   > 1. **Shape** — **simple** (one folder, several files) or **complex** (sub-folders per separable
   >    vendor sub-service or component). Pre-evaluate which fits the subject.
   > 2. **Version** — which release to document. Establish *both* the version(s) the project actually
   >    uses and the newest one upstream publishes, then ask. Never pin silently.
   >
   > **An external KB describes upstream only.** Never write the project's own installed, pinned or
   > deployed version into it. Keeping such a number true costs a KB edit on every upgrade, and nothing
   > prompts that edit. Report a disagreement between the project's version sources to the human
   > instead. The documented version, upstream markers like `[1.4]`, and dated `log.md` entries are
   > fine.

3. **The anchor** in `{Instructions_File}` — a short section, nothing more:

   ```markdown
   # {title}

   <!-- okf:installed — managed by /xnd:kb-update; edit the imported file, not this block. -->

   The operating instructions for the `{Metadata_Dir}/` bundle live in
   [{base prompt filename}]({layout.base_prompt, spaces as %20}) — read it before working in the
   bundle. Claude Code imports it here:

   @{layout.base_prompt, spaces escaped as "\ "}
   ```

   The link is for agents that do not expand `@` imports — most non-Claude tools reading `AGENTS.md`;
   the import is for Claude Code. Keep both. See [Anchor constraints](#anchor-constraints) before
   writing it — the import path has rules.

   If the human agreed to a change in another instruction file (see [Instruction file](#instruction-file)),
   make exactly that change.

4. A starter `{Metadata_Dir}/_Workflows_/Review Prompt.md` for `/xnd:project-review` to consume.
5. Vendor the spec (see [Phase 1](#phase-1--spec-drift)).

Then run the maintain flow.


## Maintain flow

### Phase 0 — Verify the installation

Runs first on every maintain run. It is cheap, and everything after it assumes the install is sound.
Steps 1–3 are the diagnosis [`/xnd:kb-check-setup`](../kb-check-setup/SKILL.md) performs read-only;
the rest repairs. Its checks are the full list of what a sound installation looks like.

1. **Resolve `{Instructions_File}`** per [Instruction file](#instruction-file) — from disk; the marker
   is invisible from context.
2. **Confirm the base prompt actually loaded — before you read its file**, or the check proves
   nothing. Its `## Bundle Configuration` table should already be in your context, expanded from the
   import at launch. If it is not, the import is broken and every session has been running without
   the bundle's rules — the worst failure this skill has, and invisible from inside a session that
   never looks. Find the cause, fix what step 5 can fix, and report the rest under *What needs you*.
   Usual causes, most likely first: a `_Name_` segment in the path (step 5), an unescaped or quoted
   space, an anchor file Claude Code does not load
   ([the facts](../kb-check-setup/SKILL.md#how-agents-load-the-instruction-files)), a missing target.
3. **Identify the shape:**
   - **Anchored** (current) — a heading, a marker comment, a sentence linking the base prompt, and
     an `@` import line of `layout.base_prompt`.
   - **Inline** (legacy) — the section carries the full instruction text directly.
   - **Absent** — run [Install](#install-flow-first-run-only) instead.
4. **Migrate inline → anchored.** Move the section body verbatim into `layout.base_prompt`; add
   frontmatter (a `type` from `vocabulary.types`, a `description`, `generated`); **rebase every
   relative link in the moved text** — the content moved down into the bundle, so every link that
   resolved from the repo root needs one `../` per level (`Notes/x.md` becomes `../x.md` from
   `Notes/Knowledge Base/`); list it in its directory's `index.md`; then replace the
   `{Instructions_File}` section with the anchor. Report the migration — it rewrites a file the human
   owns.
5. **Migrate an unloadable base prompt.** If `layout.base_prompt` contains a `_Name_` segment — any
   path segment wrapped in `_` or `*`, such as the `{Metadata_Dir}/_Workflows_/knowledge-base/` that
   v0.3.0–v0.8.0 installed by default — the import has **never loaded**
   ([Anchor constraints](#anchor-constraints)). `git mv` the base prompt and its `index.md` to
   `{Metadata_Dir}/Knowledge Base/`, cased per `naming.folders`, keeping the filename; rebase its
   relative links; update `layout.base_prompt`, the anchor's link and import, and every index that
   listed the old path; drop any `naming.reserved` / `reserved_folders` entry that existed only to
   exempt the old path. Report it first and plainly — the human has been missing these rules in every
   session since install.
6. **Migrate frontmatter config → `Configuration.yaml`.** A bundle whose root `index.md` still carries
   `okf_*` keys beyond `okf_version` predates the central config file. Move every producer-defined key
   into `{Metadata_Dir}/_Configuration_/Configuration.yaml` under its new group (`spec`, `layout`,
   `naming`, `vocabulary`, `zones`), **leave `okf_version` where it is** (OKF §12), scaffold
   `_Configuration_/index.md`, and report the migration. Never leave a key in both places.
7. **Repair the anchor** if it drifted: heading, marker comment, the sentence with its link (spaces as
   `%20`), the import line (spaces escaped as `\ `), and the import target actually existing.
8. **Regenerate the base prompt from the config.** This is the step that makes hand-editing
   `Configuration.yaml` safe, so treat it as mechanical rather than a judgement call:

   - The base prompt's `## Bundle Configuration` table is **generated**. Render it fresh from the
     config, quoting every value **verbatim in a code span** — `` `title-case` ``, not "Title Case
     with spaces". A prose paraphrase cannot be checked, and an uncheckable claim drifts.
   - Every other derived fact in the base prompt — immutable zones, the type vocabulary, the verifier
     command, naming rules, the paths in `layout` — is regenerated the same way.
   - **Compare by re-rendering, not by checksum.** A stored hash would be a second source of truth
     about the same fact, and would go stale exactly when it matters. Render, diff, rewrite on
     mismatch.

   A stale base prompt is the worst failure this skill has, because it is invisible: the file is
   expanded into context at launch and still *reads* like instruction while teaching the wrong rules.
   Where the project's verifier can check this (XND's does), say so in the report.
9. **Check distribution drift** — one small fetch, and **the direction depends on `layout.skill_source`**,
   which is what distinguishes a publisher from a consumer. Getting this backwards is the whole trap:
   a project that vendors the source will never have an update waiting for it, because it *is* the
   update.

   Read the version from the published manifest — prefer the raw file
   (`https://raw.githubusercontent.com/<owner>/<repo>/<default-branch>/plugins/<name>/.claude-plugin/plugin.json`)
   over the rendered repository page; it is a few hundred bytes and needs no parsing. Derive the URL
   from `repository` in the local `plugin.json` rather than hardcoding it.

   | `layout.skill_source` | Meaning | Compare | On drift |
   | :--- | :--- | :--- | :--- |
   | **Set** | The project vendors the source — it *is* upstream | local vs published | Local ahead → report unpublished work and name the publish command from the suite's own `MAINTAINING.md`. **Never suggest updating.** Published ahead → someone else pushed; flag it as a genuine conflict to reconcile by hand |
   | **Absent** | Read-only marketplace install — a consumer | published vs installed | Published ahead → say so, name the versions, and suggest the human update. **Never self-update an installed plugin** |

   Report it in Phase 7 as one line either way, including when versions match. Treat every failure —
   offline, rate-limited, moved repository, absent `repository` field — as **skip and stay silent**.
   A version check is a convenience; it must never block a maintenance run or spend a second attempt.

#### Anchor constraints

Five rules, each with a failure mode worth naming. Every one of them fails **silently** — a broken
import loads nothing and says nothing — which is why [Phase 0](#phase-0--verify-the-installation)
step 2 checks the result rather than trusting the line.

1. **Escape every space with a backslash.** `@Notes/Knowledge\ Base/Base\ Prompt.md` imports the
   file. Unescaped, the path ends at the first space; wrapped in quotes, nothing is imported at all.
   `layout.base_prompt` stores the real, unescaped path — escape only when writing the import line,
   and write spaces as `%20` in the markdown link beside it. The project's naming convention applies
   to these names like any other; there is no kebab-case exception.
2. **No `_Name_` segment in the path — and no escape for it.** The import parser reads the line as
   Markdown, so `/_Workflows_/` becomes emphasis and the path splits: `@Notes/_Workflows_/x.md`
   imports nothing, and so do `\_Workflows\_` and `<…>`. The same holds for any segment wrapped in
   `_` or `*`. Intraword underscores (`snake_case`) are fine. Verified 2026-10-05 against Claude Code
   2.1.289 with isolated probes. This is why the base prompt lives in `{Metadata_Dir}/Knowledge Base/`
   and never under a marker directory such as `_Workflows_/`.
3. **The import line is the marker.** HTML comments are stripped from context, so a comment-only
   marker is invisible to an agent that has not read the file from disk. Keep the comment for humans
   reading the file; rely on the import line for everything else.
4. **Externalizing does not save context.** An imported file is expanded into the context window at
   launch exactly as if it had been pasted inline. The reason to do this is **atomicity** — the skill
   owns a whole file it can regenerate, instead of surgically rewriting the human's most important
   file — not token savings. Keep the base prompt short on its own merits; if the goal is a smaller
   context, *cut* content, do not move it.
5. **Imports resolve relative to the file containing them** and nest at most four hops. A
   `CLAUDE.md` holding only `@AGENTS.md` spends one of them. Do not chain base prompts.

Hosts that do not expand `@` imports — most non-Claude agents reading `AGENTS.md` — still find the
base prompt through the anchor's markdown link. The content lives in one regenerable place either
way; only the automatic loading differs.

### Phase 1 — Spec drift

1. Fetch `https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md`.
2. Fetch its **latest commit SHA** for that path:
   `https://api.github.com/repos/GoogleCloudPlatform/knowledge-catalog/commits?path=okf/SPEC.md&per_page=1`
3. Compare against `spec.sha`.

> ⚠️ **Never decide staleness from the spec's declared version string.** On 2026-08-21 the spec
> changed materially (commit `62432a09` — every timestamp became an ISO 8601 datetime with an
> explicit UTC offset) while still declaring **Version 0.2**. A version check reports "nothing to do"
> and is wrong. The SHA is the source of truth.

4. **Vendor the spec** into `{Metadata_Dir}/_External_/OKF/` alongside its SHA, so runs are
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
7. Set `spec.sha` to the new SHA.

### Phase 1b — Self-update

A spec change that this skill's own instructions contradict does not merely leave the skill outdated —
it makes it **actively wrong**, because it will keep migrating files toward a rule that no longer
exists. The skill is therefore part of what Phase 1 migrates.

Read `layout.skill_source`.

- **Absent** — the normal case: the plugin is installed read-only from a marketplace. Write the needed
  changes into the Phase 7 report under *What needs you*, quoting the spec passage and naming the file
  and section. Never edit an installed plugin in place.
- **Set** — the project vendors this suite as source. Update it, bounded to exactly four things:
  1. **Spec facts** — field names, vocabularies, required/optional status, version strings, and every
     frontmatter example that the change would make wrong.
  2. **`## Spec baseline`** in this file — the new SHA and date.
  3. **`plugin.json` version** — patch for an editorial correction, minor for a new or changed rule.
  4. **The suite's own prose** — `README.md` and any KB documenting this suite, where they state spec
     behaviour.

**Never** change skill *behaviour* the spec did not change; a self-update is a translation, not a
redesign. **Never** touch the verifier's implementation even when `layout.skill_source` is set — that is
project source code, not skill source ([hard rule 7](#hard-rules)); report it via the
[Verifier contract](#verifier-contract). Report every self-edit in Phase 7: a skill that rewrites
itself silently cannot be audited.

### Phase 2 — Inventory & conformance

1. Run `verifier` if set. Fix every **error**. Fix **warnings in active documents**. Findings
   inside `zones.immutable` zones are unactionable by contract — leave them; and if the verifier reports
   them as ordinary findings instead of suppressing them, raise that per the
   [Verifier contract](#verifier-contract).
2. Check `generated.at` drift: compare each in-scope concept against
   `git log -1 --format=%cI -- <file>`. Where they diverge materially, set `generated.at` to the last
   commit that changed *content* — not renames or mechanical passes. Leave `generated.by` alone
   unless you rewrote the content, in which case set it to your own actor id.
3. Flag size outliers: concepts over ~500 lines or ~2,500 words are re-chunk candidates for Phase 4;
   under ~15 lines are merge candidates.
4. Check tag health against `vocabulary.tags`: values outside the vocabulary, singular/plural drift,
   concepts with 0–1 tags that deserve more.

### Phase 3 — Upstream verification (external KBs)

For **every** external KB the project has — enumerate `{Metadata_Dir}/_External_/*`, including
per-product sub-KBs; do not work from a hardcoded list:

1. Read its `gotchas.md` (version notes) and `log.md` (when last verified, against what).
2. Establish what the project **actually uses** before trusting the KB — `package.json` versions,
   lockfiles, infrastructure notes. A KB pinned to a version the project does not run is a different
   problem from a KB that is merely stale. Use what you find to steer this pass, but **do not write
   it into the KB**. Remove any back-reference to the project's versions you come across, per
   [The KB never names the project's versions](#the-kb-never-names-the-projects-versions). If the
   project's own sources disagree, report that under *What needs you*.
3. Fetch the official documentation for the *pinned or currently-used* version. Prefer the KB's own
   recorded fetch strategy (many vendors expose `llms.txt` indexes or raw markdown via a `.md`
   suffix) — each KB's `log.md` records what worked last time.
4. Compare **prioritising `gotchas.md` and version notes** — these are what agents rely on. Full
   re-verification of every chapter is not required; verify what changed upstream, changelogs first.
5. Apply updates: correct stale facts, add new gotchas, mark removed features. For a major upstream
   version, prefer adding a clearly-dated "vX changes" section over silently rewriting history.
6. **Record the pinned version** in `gotchas.md` frontmatter — `upstream: {product, version, kind}`
   and the canonical `resource:` — per [External KB metadata](#external-kb-metadata). If the KB
   already states a version only in prose, promote it; if the version genuinely changed, update it in
   the same pass as the content.
7. Append to the KB's `log.md`:
   `* **Verification**: Verified against <upstream version / docs date>; <drift found, or "no drift">.`
8. **Record the verification in frontmatter.** On each chapter you actually checked (at minimum the
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
- **Archive** superseded concepts by the ordered procedure in
  [Archiving a document](#archiving-a-document) — the stamping happens *before* the move, never after.
- **Relocate** concepts in the wrong directory (`git mv`, then fix inbound links repo-wide). **If a
  rename would break a reference in a file you must not edit, do not perform the rename — propose
  it.**
- Keep the external house style: task-oriented headings, tables for gotchas and matrices, fenced
  examples, no marketing prose.
- Numeric chapter prefixes encode reading order. Gaps after re-chunking are fine — **never renumber
  existing chapters for tidiness**; links point at them.

### Phase 5 — Re-tag & re-describe

- Apply `vocabulary.tags`; 2–5 tags per concept.
- Sharpen weak `description` lines — one specific, front-loaded sentence. Ask "what would an agent
  grep for?" The description is what index files and search snippets show.
- Express draft/deprecated lifecycle via `status: draft|stable|deprecated`, not tags — and delete any
  tag that duplicates it, so lifecycle has exactly one home and cannot drift against itself.
- A document that is superseded but still in place (an old chapter kept for its links, a stale
  external KB awaiting re-verification) is `status: deprecated` too. Saying so is more honest than
  letting it sit at `stable` and accumulate freshness warnings.

### Phase 6 — Regenerate

1. Rebuild every in-scope `index.md` from directory contents + frontmatter descriptions. Order
   most-important-first within sections (overviews and gotchas first), not alphabetical.
2. **Regenerate the external-KB registry** in `{Metadata_Dir}/_External_/index.md` from each KB's
   `gotchas.md` frontmatter — product, pinned version, and the most recent `verified.at`. Derive
   shape from the directory tree rather than reading it from anywhere. Never carry a version string
   forward by hand; if a KB has no `upstream` key yet, say so in the table rather than guessing.
3. Append `log.md` entries — bundle root always, per-KB where touched. Newest first,
   `## <date>` headings in the project's date format, bold leading verb (`**Update**`,
   `**Creation**`, `**Deprecation**`, `**Verification**`).
4. Refresh `generated.at` on every file whose *content* you changed; set `generated.by` to your actor
   id where you rewrote content.
5. Re-run `verifier` — it must exit with zero errors before you finish.

### Phase 7 — Report

See [Reporting](#reporting).


## External KB metadata

Three questions get asked of an external KB — *what shape is it?*, *what version does it describe?*,
and *what is here?* — and they have three different right answers. Collapsing them into one central
registry is tempting and wrong in a specific, checkable way.

### Shape is derived, never stored

**Simple** (one folder of chapters) versus **complex** (sub-folders per vendor sub-product) is a
question the filesystem already answers: a KB is complex when its directory holds sub-directories that
carry their own `index.md`. Recording the answer creates a second source of truth that can disagree
with the tree — and the tree always wins, so the record is at best redundant and at worst misleading.
Ask the human which shape to **create**; never ask a file which shape a KB **is**.

### Version lives with the content it describes

The pinned upstream identity belongs in the KB's own `gotchas.md` frontmatter, for three reasons in
increasing order of severity:

1. **A central `index.md` cannot hold it.** Reserved index files must not carry frontmatter, so a
   central registry could only express this as body prose — unparseable, and invisible to the trust
   machinery.
2. **Freshness is per-document.** `stale_after` and `verified` are per-file and derive the trust tier.
   A central version string would sit in a different file from the `stale_after` it is supposed to
   justify, so the two would drift with nothing to catch it.
3. **One version per KB is frequently a lie.** A KB whose chapter 10 was verified against the
   installed package while chapters 01–09 describe a version two generations older cannot be honestly
   summarised by a single number — and that is the *normal* state of a KB being repaired
   incrementally. A single field erases exactly the distinction a reader needs.

`gotchas.md` is the right file because it is already the KB's canonical head, already where version
notes live in prose, and already what [Phase 3](#phase-3--upstream-verification-external-kbs) stamps
`verified` onto.

```yaml
resource: https://github.com/sindresorhus/ky   # OKF §4 — canonical upstream for this KB
upstream:
  product: ky
  version: "2.0.2"
  kind: semver                                 # semver | sha | date
```

`upstream` is a producer-defined key; the spec explicitly permits these and requires consumers to
preserve them. **`kind` records which identifier upstream actually publishes** — do not force one
scheme. A package registry gives honest semver. A git-hosted spec gives a commit SHA, and needs to:
the OKF spec changed materially on 2026-08-21 while still declaring `Version 0.2`. A documentation
site with neither gives only the date you fetched it. `kind` tells a consumer whether comparing two
values with `>` means anything.

### Choosing the version to document

**When creating an external KB — simple or complex — never pick the version silently.** Establish
both candidates, then ask. The two are different questions and frequently have different answers:

1. **What the project uses.** Read it from the evidence, not from one file: manifest ranges
   (`package.json`), resolved lockfile entries, the installed binary (`<tool> --version`), container
   base images, and any `packageManager`/`engines` pin. **Report each separately when they disagree.**
   That disagreement is not noise to be averaged away. It is a real finding for the human, and the
   input to this decision. It is **not** KB content: see
   [The KB never names the project's versions](#the-kb-never-names-the-projects-versions).
2. **What upstream publishes now.** A registry `latest`, a releases endpoint, or the docs site.

Then ask which to document, marking one `(recommended)`:

* **Recommend the in-use version by default.** A KB's primary job is to describe the code that
  actually runs; a reader debugging production needs the behaviour they have, not the behaviour they
  could have.
* **Recommend the newest** when the gap spans a major or a substantial minor and the human's intent is
  to evaluate or plan an upgrade. Say what the gap contains, so the choice is informed.

Record the answer in `gotchas.md` `upstream:` as always. **When the documented version is newer than
the in-use version, the KB must additionally carry both of these** — the inversion is a trap
otherwise, because every unavailable API reads as available:

* An inline marker on every fact upstream added or changed after the in-use version — `[1.4]`,
  `[v3]`, whatever matches the `kind`. Unmarked content must hold on the older versions too.
* A banner on the KB's root `index.md` naming the **documented** version, stating the marker
  convention, and saying plainly that a marked feature missing from the reader's binary means the KB
  is ahead of them, not wrong.

#### The KB never names the project's versions

An external KB describes **upstream**. It must not state which version the project installs, pins,
bundles or deploys: no "the installed binary is …", no "the repo pins `tool@…`", no "the Docker tag
resolves to …", no table of the project's version sources.

**The reason is maintenance overhead.** Every package-manager upgrade or image rebuild would need a
matching KB edit. Nothing prompts that edit, and a stale number still reads as verified. The in-use
version is used **while writing**, to make the recommendation above and to decide which facts get a
marker. It is never written down. A reader who needs it checks the project itself.

**Where it applies:** external KBs (`_External_/`), meaning documentation of someone else's product.
The project's own docs (setup notes, a version-pinning workflow) are where in-use versions belong.
Ideally they live in one place that lists every pin, so an upgrade edits one list instead of hunting
through KBs.

Allowed, because none of them back-references the project:

* the documented upstream version — `gotchas.md` `upstream:` and the root banner;
* upstream markers — `[1.4]` reads "upstream added or changed this in 1.4";
* dated `log.md` entries, which record what was true when written rather than claim it now.

A drift *between* the project's own version sources (an unenforced pin, a floating container tag) is
a finding for the human or the project's task list, not a gotcha.

> **Worked counter-example.** The XANDERIA Bun KB was re-pinned to 1.4.0 on 2026-09-03 and named four
> project versions in its banner and first gotcha: installed binary, `packageManager` pin, Docker tag,
> `@types`. Within a month the binary and the Docker tag had both moved to 1.4.2. The banner still
> said "nothing in XANDERIA runs 1.4", and a prompt every session loaded repeated the stale number.
> The `[1.4]` markers stayed correct throughout, because they describe upstream.

The same question applies on a **re-pin** during [Phase 3](#phase-3--upstream-verification-external-kbs):
if verification finds the KB pinned to a version the project no longer uses, ask before moving it.
Silently re-pinning discards the record of what the last verification actually checked.

### The central index is generated, not authored

A registry of *what exists, at what version, last checked when* is genuinely useful — for discovery.
It must be **generated from the per-KB frontmatter in [Phase 6](#phase-6--regenerate)**, never
hand-maintained, because a hand-maintained copy drifts silently and nothing lints prose.

This is not hypothetical. The XANDERIA bundle's `_External_/index.md` described its OKF KB as
*"Open Knowledge Format v0.1"* for **five weeks** after the bundle moved to v0.2 — while the KB's own
files, its `log.md` and the bundle config all said v0.2 correctly. The single authored copy was the
only thing that was wrong, and no check could have caught it.

So: **truth per-KB in frontmatter; the central table is a generated cache with a known generator;
shape is computed on demand.** The direction of flow is always per-KB → central, never the reverse.


## Archiving a document

Archiving is a **one-way door**: the moment a file lands in an `zones.immutable` zone, its frontmatter
may never be touched again. Everything that must be true of it forever therefore has to be made true
*before* the move. Getting this order wrong is how a bundle ends up with archived files stranded on a
spec version nobody is permitted to migrate them off.

In order:

1. **Rescue what is still live.** Read the document for unfinished business — unchecked boxes, open
   questions, deferred decisions — and move each one somewhere active: an open plan, the relevant
   concept document, or a project's issue tracker. The archive is where open items go to die quietly,
   because the `git mv` is the last moment anyone reads them. Verify the finished parts really are
   finished rather than trusting the document's own account of itself; a plan that says a step remains
   may be describing work that has since shipped, and one that says a step is done may be wrong.
2. **Stamp the lifecycle** — `status: deprecated`.
3. **Remove `stale_after`.** It is a promise to re-verify by a date, and an archived document makes no
   promises; it is history, not stale guidance. Delete the key — never push it into the far future,
   which asserts a freshness the document does not have and quietly lies to every consumer.
4. **Drop the lifecycle tag** the project may have used (`deprecated`, `obsolete`, `draft`). Lifecycle
   now lives in `status`; a tag repeating it is a second source of truth waiting to drift.
5. **Bring it fully up to the current spec.** This is its last opportunity to be migrated.
6. **Move it** (`git mv`) into the archive folder.
7. **Repoint the living, not the dead.** Update active documents that relied on it so they point at
   the successor. Links *into* the archive are fine and often correct ("superseded by X"); links *out
   of* the archive are frozen wherever they pointed, resolving or not.
8. **Index both ends** — add an entry to the archive's `index.md` naming the successor, and remove the
   entry from the index it left.
9. **Log it** — a `**Deprecation**` entry recording what replaced it and why.

From step 6 the file is immutable. Never edit it again except under the narrow spec-migration
exception in [hard rule 3](#hard-rules).


## Verifier contract

`verifier` is the project's own tool, but a verifier blind to `zones.immutable` emits findings
nobody is permitted to act on — and a linter whose output you must learn to ignore is worse than no
linter, because it teaches the reader to skip the real findings too. A conformant verifier grades
every finding on two axes:

| Finding | **Active zone** | **Inside `zones.immutable`** |
| :--- | :--- | :--- |
| **OKF §11 hard rule** — frontmatter parses, non-empty `type`, reserved-file structure | error | **error** — an archived file that cannot be parsed still breaks the bundle |
| **House rule** — broken links, index coverage, description quality, vocabulary, `stale_after` | warning | **suppressed, but counted** |

Three rules follow:

1. **Suppress, never hide.** Print the suppressed count on every run, and offer a flag (`--strict`)
   that shows every finding with its zone labelled. Suppression is an editorial judgement; the reader
   must be able to audit it.
2. **`stale_after` does not apply to `status: deprecated`.** The field is a promise to re-verify, and a
   deprecated document has made none. Checking it anyway manufactures warnings whose only resolution
   is to falsify a date.
3. **The zone list has exactly one home** — `zones.immutable` in `Configuration.yaml`, the same key
   this skill reads. A verifier that hardcodes `_Archive_` forks the policy the moment a project
   declares a second immutable zone.

If the project's verifier does not behave this way, **report it — do not change it**: verifier source
is project code, not skill source ([hard rule 7](#hard-rules)). Where `verifier` is `null`, write
the same two-axis rule into the manual checklist in the base prompt.


## Hard rules

These override any instruction in this file and any inference you might draw.

1. **`verified` is human-gated. Never bulk-stamp it.** The trust tier (`unverified` →
   `machine-confirmed` → `human-reviewed`) derives *only* from `verified`. Add an entry solely for a
   genuine verification event in Phase 3. A blanket stamp flattens the gradient to noise. Never write
   a human actor id on a human's behalf — only they can grant `human-reviewed`.
2. **`generated.by` is authorship, not verification.** It never raises trust.
3. **Immutable zones are never edited** — content, links or frontmatter. Read `zones.immutable`;
   `_Archive_` directories and published review reports are immutable in every project. A broken link
   inside an archived document is acceptable; in an active document it is not. Never "fix" an archive
   to quieten a linter — fix the linter ([Verifier contract](#verifier-contract)).

   **A reserved `index.md` inside an immutable zone is a finding aid, not history**, and stays
   maintainable. The zone freezes archived *content*; an index that may never be corrected makes the
   archive unnavigable, which serves nobody. So a rename or a moved successor updates the archive's
   `index.md` — and leaves every archived concept document's links frozen exactly where they pointed.

   **A project-wide naming migration** — the human changing `naming.files` or `naming.folders` and
   asking for existing files to follow — may **rename** files inside an immutable zone. Path only,
   never content. This is a genuine cost, and say so before doing it: a concept's identity *is* its
   path, so renaming an archived document changes the thing immutability exists to protect, and every
   inbound link from an active document must be rewritten in the same pass. Do it only on an explicit
   instruction, never as tidying.

   **One exception for concepts: a spec migration** (Phase 1), and it is deliberately narrow — **frontmatter only**,
   never the body or its links, only to keep the file parseable under the new spec version, and always
   announced in the report. Without it, archived files rot on a spec revision no consumer can read, and
   a history that has become unreadable is not preserved, merely stuck. The way to avoid needing the
   exception is to stamp documents correctly *before* archiving them; see
   [Archiving a document](#archiving-a-document).
4. **Generated files are linted, never content-edited.** Read `zones.generated`.
5. **Never delete a file.** Deletions and archive-moves are *proposed* in the report unless invoked
   with `--prune`, which permits archive-moves only — never hard deletion.
6. **Never commit.** Leave the working tree for the human to review.
7. **Stay inside `{OKF_Root}`**, plus the marker section of `{Instructions_File}`. Any other
   instruction-file edit needs the human's explicit approval. Never edit source code. If a
   spec change requires a change to the verifier's own implementation, **report it — do not make
   it.**
8. **Timestamps are ISO 8601 with an explicit UTC offset**, per spec. `2026-08-26T00:00:00Z`, never
   a bare date.


## Reporting

End with a **concise, joyous, beginner-friendly** report. Assume the reader does not know OKF
jargon — say "added a summary line so search results read better", not "populated the description
field". Lead with the lion and `title`.

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
  `{Metadata_Dir}/_External_/`.
- **`spec`** — Phase 1 only. Fast check for spec drift.
- **`core`** — structure and accuracy pass on everything *except* `{Metadata_Dir}/_External_/`;
  cross-check docs against code, then fix rather than report.
- **`<kb-name>`** — full treatment of one external KB and its sub-KBs. Recommended quarterly, or
  before a major dependency upgrade.
- **`--prune`** — combinable with any scope; see hard rule 5.
- **anything else** — free-form focus instruction; scope accordingly.

$ARGUMENTS
